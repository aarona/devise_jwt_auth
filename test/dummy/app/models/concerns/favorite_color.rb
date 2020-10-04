# frozen_string_literal: true

module FavoriteColor
  extend ActiveSupport::Concern

  included do
    validates :operating_thetan, numericality: true, allow_nil: true
    validate :ensure_correct_favorite_color
  end

  def ensure_correct_favorite_color
    return unless favorite_color && (favorite_color != '')

    return if ApplicationHelper::COLOR_NAMES.any? { |s| s.casecmp(favorite_color).zero? }

    matches = ApplicationHelper::COLOR_SEARCH.search(favorite_color)
    closest_match = matches.last[:string]
    second_closest_match = matches[-2][:string]
    errors.add(:favorite_color, "We've never heard of the color \"#{favorite_color}\". Did you mean \"#{closest_match}\"? Or perhaps \"#{second_closest_match}\"?")
  end
end
