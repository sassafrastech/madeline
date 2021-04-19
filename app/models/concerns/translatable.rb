module Translatable
  extend ActiveSupport::Concern

  included do
    has_many :translations, as: :translatable, autosave: true, dependent: :destroy
    accepts_nested_attributes_for :translations
  end

  module ClassMethods
    # define convenience methods for assigning and fetching the named attribute
    #
    # equivalent to:
    #
    # def foo
    #   get_translation('foo')
    # end
    #
    # def foo_en
    #   get_translation('foo', locale: :en)
    # end
    #
    # def foo=(text)
    #   set_translation('foo', text)
    # end
    #
    # def foo_en=(text)
    #   set_translation('foo', text, locale: :en)
    # end
    #
    # def clear_foo_en
    #   delete_translation('foo', :en)
    # end
    #
    # def set_foo(text, locale)
    #   set_translation('foo', text, locale)
    # end
    #
    # def foo_translations
    #   get_translations('foo')
    # end
    #
    # def foo_translations=(translations)
    #   set_translations('foo', translations)
    # end
    #
    # def locale_en
    #   :en
    # end

    def translates(*attributes, allow_html: false)
      # attribute methods
      attributes.each do |attribute|
        define_method(attribute) { get_translation(attribute) }
        define_method("#{attribute}=") { |text| set_translation(attribute, text, allow_html: allow_html) }
        define_method("set_#{attribute}") do |text, locale: I18n.locale|
          set_translation(attribute, text, locale: locale, allow_html: allow_html)
        end
        define_method("#{attribute}_translations") { get_translations(attribute) }
        define_method("#{attribute}_translations=") do |translations|
          set_translations(attribute, translations, allow_html: allow_html)
        end
        alias_method "set_#{attribute}_translations", "#{attribute}_translations="
        I18n.available_locales.each do |locale|
          define_method("#{attribute}_#{locale}") { get_translation(attribute, locale: locale) }
          define_method("#{attribute}_#{locale}=") do |text|
            set_translation(attribute, text, locale: locale, allow_html: allow_html)
          end
          define_method("clear_#{attribute}_#{locale}") { delete_translation(attribute, locale) }
        end
      end
      # locale methods
      I18n.available_locales.each do |locale|
        define_method("locale_#{locale.to_s}") { locale }
      end
    end
  end

  def get_translation(attribute, locale: I18n.locale, exact_match: false)
    # It is important to filter against the association held in memory (instead of fetching the data from the DB)
    # in order to redisplay potentially transient values when there is a validation error and a form needs to be
    # displayed with values not yet # saved to the DB.
    result = translations.find do |t|
      t.translatable_attribute.to_sym == attribute.to_sym && t.locale.to_sym == locale.to_sym
    end
    unless result || exact_match
      # When we are just displaying a translatable value, we'll show the user's default locale,
      # but if not available, then we'll show the first available one. In this case `exact_match:false` is passed in.
      # When editing a form, we only want resolve the exact locale provided and `exact_match:true` is passed in.
      result = translations.find do |t|
        t.translatable_attribute.to_sym == attribute.to_sym
      end
    end
    result
  end

  def get_translations(attribute)
    # Shouldn't use scope here because it won't work if translations have just been assigned
    # and object hasn't been saved.
    translations.select { |t| t.translatable_attribute.to_s == attribute.to_s }
  end

  def used_locales
    # Shouldn't use scope here because it won't work if translations have just been assigned
    translations.map { |t| t.locale.to_sym }.sort
  end

  def division_locales
    return [] unless respond_to?(:division)
    division.locales
  end

  # Returns locales that have been assigned to the division, or an array
  # containing only the current locale if there are no translations.
  # Orders additional locales by locale code
  def used_and_division_locales
    locales = (used_locales + division_locales).uniq
    if locales.include?(I18n.locale)
      # Make sure default locale is displayed first if present
      [I18n.locale] | locales
    else
      locales.presence || [I18n.locale]
    end
  end

  def deleted_locales=(locales)
    locales.each do |l|
      # We don't want to destroy translations that have changed since being loaded.
      # Only existing, unchanged translations.
      translations.each{ |t| t.destroy if t.locale.to_sym == l.to_sym && t.persisted? && !t.text_changed? }
    end
  end

  def delete_translation(attribute, locale)
    translation = get_translation(attribute, locale: locale, exact_match: true)
    translation.delete if translation
  end

  # if old_locale is provided and different from locale, then the language for an existing set of translations
  # was changed from one language to another within the edit UI, and we need to match against that existing record
  # when fetching for the update
  def set_translation(attribute, text, locale: I18n.locale, old_locale: nil, allow_html:)
    translation = get_translation(attribute, locale: old_locale || locale, exact_match: true)
    if translation
      translation.assign_attributes(text: text, locale: locale, allow_html: allow_html)
    else
      translations.build(translatable_attribute: attribute, locale: locale, text: text, allow_html: allow_html)
    end
    text
  end

  def set_translations(attribute, translations = {}, allow_html:)
    translations.each do |locale, text|
      set_translation(attribute, text, locale: locale, allow_html: allow_html)
    end
  end

  # Clones all translations associated with current instance into target translatable instance as
  # transient values.
  def clone_translations(destination)
    translations.each do |translation|
      destination.translations.build(
        translatable_attribute: translation.translatable_attribute,
        locale: translation.locale,
        text: translation.text
      )
    end
  end

  # returns the element from the parent objects association list for the given object's id
  # necessary to get autosave behavior to work as desired
  # def associated_translation(translation)
  #   if translation
  #     translations.find{|t| t.id == translation.id}
  #   else
  #     translation
  #   end
  # end

  class TranslationPresenceValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      # Ensure each translation given is not blank.
      record.send("#{attribute}_translations").each do |t|
        record.errors.add("#{attribute}_#{t.locale}", :blank) if t.text.blank?
      end
    end
  end

  class AnyTranslationPresenceValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      # Ensure at least one translation given is not blank
      translations = record.send("#{attribute}_translations")

      empty_translations = translations.map do |translation|
        return if translation.text.present?;
        translation
      end

      empty_translations.each do |translation|
        record.errors.add("#{attribute}_#{translation.locale}", :blank)
      end
    end
  end
end
