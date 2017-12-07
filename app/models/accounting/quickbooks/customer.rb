# Customer in QB = Organization (Coop) in Madeline
#
# Represents a QB Customer object and can create a reference object
# for a link to this object in a transaction or other QB object.
module Accounting
  module Quickbooks
    class Customer
      attr_reader :qb_connection, :organization

      def initialize(qb_connection:, organization:)
        @qb_connection = qb_connection
        @organization = organization
      end

      # We may be creating a customer here if needed. We return the qb_id and manualy create a reference.
      # The gem does not implement a helper method for _id like account or class.
      def reference
        qb_customer_id = find_or_create_qb_customer_id

        entity = ::Quickbooks::Model::Entity.new
        entity.type = 'Customer'
        entity_ref = ::Quickbooks::Model::BaseReference.new(qb_customer_id)
        entity.entity_ref = entity_ref

        organization.update!(qb_id: qb_customer_id)

        entity
      end

      private

      def service
        @service ||= ::Quickbooks::Service::Customer.new(qb_connection.auth_details)
      end

      def find_or_create_qb_customer_id
        return organization.qb_id if organization.qb_id.present?

        normalized_name = organization.name.tr(':', '_')

        qb_customer = ::Quickbooks::Model::Customer.new
        qb_customer.display_name = normalized_name

        new_qb_customer = service.create(qb_customer)

        new_qb_customer.id
      rescue ::Quickbooks::IntuitRequestException => e
        if e.message =~ /^Duplicate Name Exists Error/
          id = service.query("select * from Customer where DisplayName = '#{normalized_name}'").first.id
          raise e unless id
          id
        else
          raise e
        end
      end
    end
  end
end
