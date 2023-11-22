# frozen_string_literal: true

module Addressing
  class Address
    attr_reader :country_code, :administrative_area, :locality, :dependent_locality, :postal_code, :sorting_code, :address_line1, :address_line2, :address_line3, :organization, :given_name, :additional_name, :family_name, :locale

    def initialize(country_code: "", administrative_area: "", locality: "", dependent_locality: "", postal_code: "", sorting_code: "", address_line1: "", address_line2: "", address_line3: "", organization: "", given_name: "", additional_name: "", family_name: "", locale: "und")
      @country_code = country_code
      @administrative_area = administrative_area
      @locality = locality
      @dependent_locality = dependent_locality
      @postal_code = postal_code
      @sorting_code = sorting_code
      @address_line1 = address_line1
      @address_line2 = address_line2
      @address_line3 = address_line3
      @organization = organization
      @given_name = given_name
      @additional_name = additional_name
      @family_name = family_name
      @locale = locale
    end

    def with_country_code(country_code)
      address = clone
      address.country_code = country_code
      address
    end

    def with_administrative_area(administrative_area)
      address = clone
      address.administrative_area = administrative_area
      address
    end

    def with_locality(locality)
      address = clone
      address.locality = locality
      address
    end

    def with_dependent_locality(dependent_locality)
      address = clone
      address.dependent_locality = dependent_locality
      address
    end

    def with_postal_code(postal_code)
      address = clone
      address.postal_code = postal_code
      address
    end

    def with_sorting_code(sorting_code)
      address = clone
      address.sorting_code = sorting_code
      address
    end

    def with_address_line1(address_line1)
      address = clone
      address.address_line1 = address_line1
      address
    end

    def with_address_line2(address_line2)
      address = clone
      address.address_line2 = address_line2
      address
    end

    def with_address_line3(address_line3)
      address = clone
      address.address_line3 = address_line3
      address
    end

    def with_organization(organization)
      address = clone
      address.organization = organization
      address
    end

    def with_given_name(given_name)
      address = clone
      address.given_name = given_name
      address
    end

    def with_additional_name(additional_name)
      address = clone
      address.additional_name = additional_name
      address
    end

    def with_family_name(family_name)
      address = clone
      address.family_name = family_name
      address
    end

    def with_locale(locale)
      address = clone
      address.locale = locale
      address
    end

    protected

    attr_writer :country_code, :administrative_area, :locality, :dependent_locality, :postal_code, :sorting_code, :address_line1, :address_line2, :address_line3, :organization, :given_name, :additional_name, :family_name, :locale
  end
end
