# frozen_string_literal: true

require 'logger'
require 'oauth2'
require 'oauth2/error'
require 'net/http'
require 'json'

require 'refinements/strings'

require 'business_central/object/url_helper'
require 'business_central/object/object_helper'
require 'business_central/object/filtered_debug_output'
require 'business_central/object/response'
require 'business_central/object/request'
require 'business_central/object/filter_query'
require 'business_central/object/url_builder'
require 'business_central/object/base'
require 'business_central/object/companies'
require 'business_central/object/picture'
require 'business_central/object/attachments'

require 'business_central/exceptions'
require 'business_central/client'
require 'business_central/web_service'

module BusinessCentral
  KNOWN_BC_ENTITIES = %w[
    vendors customers items companies
    sales_invoices sales_orders sales_credit_memos sales_quotes
    purchase_invoices purchase_orders
    general_ledger_entries
    accounts journals journal_lines
    employees dimensions default_dimensions
    currencies countries_regions payment_terms payment_methods
    shipment_methods item_categories
    tax_groups tax_areas
    units_of_measure
    picture attachments
    company_information
  ].freeze
end
