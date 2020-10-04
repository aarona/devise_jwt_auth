# frozen_string_literal: true

module ActionDispatch::Routing
  class Mapper
    def mount_devise_jwt_auth_for(resource, opts)
      # ensure objects exist to simplify attr checks
      opts[:controllers] ||= {}
      opts[:skip]        ||= []

      # check for ctrl overrides, fall back to defaults
      sessions_ctrl      = opts[:controllers][:sessions] || 'devise_jwt_auth/sessions'
      registrations_ctrl = opts[:controllers][:registrations] || 'devise_jwt_auth/registrations'
      passwords_ctrl     = opts[:controllers][:passwords] || 'devise_jwt_auth/passwords'
      confirmations_ctrl = opts[:controllers][:confirmations] || 'devise_jwt_auth/confirmations'
      refresh_token_ctrl = opts[:controllers][:refresh_token] || 'devise_jwt_auth/refresh_token'
      omniauth_ctrl      = opts[:controllers][:omniauth_callbacks] || 'devise_jwt_auth/omniauth_callbacks'
      unlocks_ctrl       = opts[:controllers][:unlocks] || 'devise_jwt_auth/unlocks'

      # define devise controller mappings
      controllers = { sessions: sessions_ctrl,
                      registrations: registrations_ctrl,
                      passwords: passwords_ctrl,
                      confirmations: confirmations_ctrl }

      controllers[:unlocks] = unlocks_ctrl if unlocks_ctrl

      # remove any unwanted devise modules
      opts[:skip].each { |item| controllers.delete(item) }

      devise_for resource.pluralize.underscore.gsub('/', '_').to_sym,
                 class_name: resource,
                 module: :devise,
                 path: opts[:at].to_s,
                 controllers: controllers,
                 skip: opts[:skip] + [:omniauth_callbacks]

      unnest_namespace do
        # get full url path as if it were namespaced
        full_path = "#{@scope[:path]}/#{opts[:at]}"

        # get namespace name
        namespace_name = @scope[:as]

        # clear scope so controller routes aren't namespaced
        @scope = ActionDispatch::Routing::Mapper::Scope.new(
          path: '',
          shallow_path: '',
          constraints: {},
          defaults: {},
          options: {},
          parent: nil
        )

        mapping_name = resource.underscore.gsub('/', '_')
        mapping_name = "#{namespace_name}_#{mapping_name}" if namespace_name

        devise_scope mapping_name.to_sym do
          # path to refresh access tokens
          unless opts[:skip].include?(:refresh_token)
            get "#{full_path}/refresh_token", controller: refresh_token_ctrl.to_s, action: 'show'
          end

          # omniauth routes. only define if omniauth is installed and not skipped.
          if defined?(::OmniAuth) && !opts[:skip].include?(:omniauth_callbacks)
            match "#{full_path}/failure",
                  controller: omniauth_ctrl,
                  action: 'omniauth_failure',
                  via: [:get]
            match "#{full_path}/:provider/callback",
                  controller: omniauth_ctrl,
                  action: 'omniauth_success',
                  via: [:get]
            match "#{DeviseJwtAuth.omniauth_prefix}/:provider/callback",
                  controller: omniauth_ctrl,
                  action: 'redirect_callbacks',
                  via: [:get, :post]
            match "#{DeviseJwtAuth.omniauth_prefix}/failure",
                  controller: omniauth_ctrl,
                  action: 'omniauth_failure',
                  via: [:get, :post]

            # preserve the resource class thru oauth authentication by setting name of
            # resource as "resource_class" param
            match "#{full_path}/:provider", to: redirect { |params, request|
              # get the current querystring
              qs = CGI.parse(request.env['QUERY_STRING'])

              # append name of current resource
              qs['resource_class'] = [resource]
              qs['namespace_name'] = [namespace_name] if namespace_name

              set_omniauth_path_prefix!(DeviseJwtAuth.omniauth_prefix)

              redirect_params = {}.tap { |hash| qs.each { |k, v| hash[k] = v.first } }

              if DeviseJwtAuth.redirect_whitelist
                redirect_url = request.params['auth_origin_url']
                unless DeviseJwtAuth::Url.whitelisted?(redirect_url)
                  message = I18n.t(
                    'devise_jwt_auth.registrations.redirect_url_not_allowed',
                    redirect_url: redirect_url
                  )
                  redirect_params['message'] = message
                  next "#{::OmniAuth.config.path_prefix}/failure?#{redirect_params.to_param}"
                end
              end

              # re-construct the path for omniauth
              "#{::OmniAuth.config.path_prefix}/#{params[:provider]}?#{redirect_params.to_param}"
            }, via: [:get]
          end
        end
      end
    end

    # this allows us to use namespaced paths without namespacing the routes
    def unnest_namespace
      current_scope = @scope.dup
      yield
    ensure
      @scope = current_scope
    end

    # ignore error about omniauth/multiple model support
    def set_omniauth_path_prefix!(path_prefix)
      ::OmniAuth.config.path_prefix = path_prefix
    end
  end
end
