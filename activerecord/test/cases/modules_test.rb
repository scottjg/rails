require "cases/helper"
require 'models/company_in_module'

class ModulesTest < ActiveRecord::TestCase
  fixtures :accounts, :companies, :projects, :developers

  def test_module_spanning_associations
    # TODO re-enable when association support is being re-enabled
    pending do
      firm = MyApplication::Business::Firm.find(:first)
      assert !firm.clients.empty?, "Firm should have clients"
      assert_nil firm.class.table_name.match('::'), "Firm shouldn't have the module appear in its table name"
    end
  end

  def test_module_spanning_has_and_belongs_to_many_associations
    # TODO re-enable when association support is being re-enabled
    pending do
      project = MyApplication::Business::Project.find(:first)
      project.developers << MyApplication::Business::Developer.create("name" => "John")
      assert "John", project.developers.last.name
    end
  end

  def test_associations_spanning_cross_modules
    # TODO re-enable when association support is being re-enabled
    pending do
      account = MyApplication::Billing::Account.find(:first, :order => 'id')
      assert_kind_of MyApplication::Business::Firm, account.firm
      assert_kind_of MyApplication::Billing::Firm, account.qualified_billing_firm
      assert_kind_of MyApplication::Billing::Firm, account.unqualified_billing_firm
      assert_kind_of MyApplication::Billing::Nested::Firm, account.nested_qualified_billing_firm
      assert_kind_of MyApplication::Billing::Nested::Firm, account.nested_unqualified_billing_firm
    end
  end

  def test_find_account_and_include_company
    # TODO re-enable when association support is being re-enabled
    pending do
      account = MyApplication::Billing::Account.find(1, :include => :firm)
      assert_kind_of MyApplication::Business::Firm, account.instance_variable_get('@firm')
      assert_kind_of MyApplication::Business::Firm, account.firm
    end
  end

  def test_table_name
    assert_equal 'accounts', MyApplication::Billing::Account.table_name, 'table_name for ActiveRecord model in module'
    assert_equal 'companies', MyApplication::Business::Client.table_name, 'table_name for ActiveRecord model subclass'
    assert_equal 'company_contacts', MyApplication::Business::Client::Contact.table_name, 'table_name for ActiveRecord model enclosed by another ActiveRecord model'
  end
end
