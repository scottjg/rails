# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{activerecord}
  s.version = "2.3.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Heinemeier Hansson"]
  s.autorequire = %q{active_record}
  s.date = %q{2010-08-18}
  s.description = %q{Implements the ActiveRecord pattern (Fowler, PoEAA) for ORM. It ties database tables and classes together for business objects, like Customer or Subscription, that can find, save, and destroy themselves without resorting to manual SQL.}
  s.email = %q{david@loudthinking.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["Rakefile", "install.rb", "README", "RUNNING_UNIT_TESTS", "CHANGELOG", "lib/active_record", "lib/active_record/aggregations.rb", "lib/active_record/association_preload.rb", "lib/active_record/associations", "lib/active_record/associations/association_collection.rb", "lib/active_record/associations/association_proxy.rb", "lib/active_record/associations/belongs_to_association.rb", "lib/active_record/associations/belongs_to_polymorphic_association.rb", "lib/active_record/associations/has_and_belongs_to_many_association.rb", "lib/active_record/associations/has_many_association.rb", "lib/active_record/associations/has_many_through_association.rb", "lib/active_record/associations/has_one_association.rb", "lib/active_record/associations/has_one_through_association.rb", "lib/active_record/associations.rb", "lib/active_record/attribute_methods.rb", "lib/active_record/autosave_association.rb", "lib/active_record/base.rb", "lib/active_record/batches.rb", "lib/active_record/calculations.rb", "lib/active_record/callbacks.rb", "lib/active_record/connection_adapters", "lib/active_record/connection_adapters/abstract", "lib/active_record/connection_adapters/abstract/connection_pool.rb", "lib/active_record/connection_adapters/abstract/connection_specification.rb", "lib/active_record/connection_adapters/abstract/database_limits.rb", "lib/active_record/connection_adapters/abstract/database_statements.rb", "lib/active_record/connection_adapters/abstract/query_cache.rb", "lib/active_record/connection_adapters/abstract/quoting.rb", "lib/active_record/connection_adapters/abstract/schema_definitions.rb", "lib/active_record/connection_adapters/abstract/schema_statements.rb", "lib/active_record/connection_adapters/abstract_adapter.rb", "lib/active_record/connection_adapters/mysql_adapter.rb", "lib/active_record/connection_adapters/postgresql_adapter.rb", "lib/active_record/connection_adapters/sqlite3_adapter.rb", "lib/active_record/connection_adapters/sqlite_adapter.rb", "lib/active_record/dirty.rb", "lib/active_record/dynamic_finder_match.rb", "lib/active_record/dynamic_scope_match.rb", "lib/active_record/fixtures.rb", "lib/active_record/locale", "lib/active_record/locale/en.yml", "lib/active_record/locking", "lib/active_record/locking/optimistic.rb", "lib/active_record/locking/pessimistic.rb", "lib/active_record/migration.rb", "lib/active_record/named_scope.rb", "lib/active_record/nested_attributes.rb", "lib/active_record/observer.rb", "lib/active_record/query_cache.rb", "lib/active_record/reflection.rb", "lib/active_record/schema.rb", "lib/active_record/schema_dumper.rb", "lib/active_record/serialization.rb", "lib/active_record/serializers", "lib/active_record/serializers/json_serializer.rb", "lib/active_record/serializers/xml_serializer.rb", "lib/active_record/session_store.rb", "lib/active_record/test_case.rb", "lib/active_record/timestamp.rb", "lib/active_record/transactions.rb", "lib/active_record/validations.rb", "lib/active_record/version.rb", "lib/active_record.rb", "lib/activerecord.rb", "test/assets", "test/assets/example.log", "test/assets/flowers.jpg", "test/cases", "test/cases/aaa_create_tables_test.rb", "test/cases/active_schema_test_mysql.rb", "test/cases/active_schema_test_postgresql.rb", "test/cases/adapter_test.rb", "test/cases/aggregations_test.rb", "test/cases/ar_schema_test.rb", "test/cases/associations", "test/cases/associations/belongs_to_associations_test.rb", "test/cases/associations/callbacks_test.rb", "test/cases/associations/cascaded_eager_loading_test.rb", "test/cases/associations/eager_load_includes_full_sti_class_test.rb", "test/cases/associations/eager_load_nested_include_test.rb", "test/cases/associations/eager_singularization_test.rb", "test/cases/associations/eager_test.rb", "test/cases/associations/extension_test.rb", "test/cases/associations/habtm_join_table_test.rb", "test/cases/associations/has_and_belongs_to_many_associations_test.rb", "test/cases/associations/has_many_associations_test.rb", "test/cases/associations/has_many_through_associations_test.rb", "test/cases/associations/has_one_associations_test.rb", "test/cases/associations/has_one_through_associations_test.rb", "test/cases/associations/inner_join_association_test.rb", "test/cases/associations/inverse_associations_test.rb", "test/cases/associations/join_model_test.rb", "test/cases/associations_test.rb", "test/cases/attribute_methods_test.rb", "test/cases/autosave_association_test.rb", "test/cases/base_test.rb", "test/cases/batches_test.rb", "test/cases/binary_test.rb", "test/cases/calculations_test.rb", "test/cases/callbacks_observers_test.rb", "test/cases/callbacks_test.rb", "test/cases/class_inheritable_attributes_test.rb", "test/cases/column_alias_test.rb", "test/cases/column_definition_test.rb", "test/cases/connection_pool_test.rb", "test/cases/connection_test_firebird.rb", "test/cases/connection_test_mysql.rb", "test/cases/copy_table_test_sqlite.rb", "test/cases/database_statements_test.rb", "test/cases/datatype_test_postgresql.rb", "test/cases/date_time_test.rb", "test/cases/default_test_firebird.rb", "test/cases/defaults_test.rb", "test/cases/deprecated_finder_test.rb", "test/cases/dirty_test.rb", "test/cases/finder_respond_to_test.rb", "test/cases/finder_test.rb", "test/cases/fixtures_test.rb", "test/cases/helper.rb", "test/cases/i18n_test.rb", "test/cases/inheritance_test.rb", "test/cases/invalid_date_test.rb", "test/cases/json_serialization_test.rb", "test/cases/lifecycle_test.rb", "test/cases/locking_test.rb", "test/cases/method_scoping_test.rb", "test/cases/migration_test.rb", "test/cases/migration_test_firebird.rb", "test/cases/mixin_test.rb", "test/cases/modules_test.rb", "test/cases/multiple_db_test.rb", "test/cases/named_scope_test.rb", "test/cases/nested_attributes_test.rb", "test/cases/pk_test.rb", "test/cases/pooled_connections_test.rb", "test/cases/query_cache_test.rb", "test/cases/readonly_test.rb", "test/cases/reflection_test.rb", "test/cases/reload_models_test.rb", "test/cases/repair_helper.rb", "test/cases/reserved_word_test_mysql.rb", "test/cases/sanitize_test.rb", "test/cases/schema_authorization_test_postgresql.rb", "test/cases/schema_dumper_test.rb", "test/cases/schema_test_postgresql.rb", "test/cases/serialization_test.rb", "test/cases/synonym_test_oracle.rb", "test/cases/timestamp_test.rb", "test/cases/transactions_test.rb", "test/cases/unconnected_test.rb", "test/cases/validations_i18n_test.rb", "test/cases/validations_test.rb", "test/cases/xml_serialization_test.rb", "test/cases/yaml_serialization_test.rb", "test/config.rb", "test/connections", "test/connections/jdbc_jdbcderby", "test/connections/jdbc_jdbcderby/connection.rb", "test/connections/jdbc_jdbch2", "test/connections/jdbc_jdbch2/connection.rb", "test/connections/jdbc_jdbchsqldb", "test/connections/jdbc_jdbchsqldb/connection.rb", "test/connections/jdbc_jdbcmysql", "test/connections/jdbc_jdbcmysql/connection.rb", "test/connections/jdbc_jdbcpostgresql", "test/connections/jdbc_jdbcpostgresql/connection.rb", "test/connections/jdbc_jdbcsqlite3", "test/connections/jdbc_jdbcsqlite3/connection.rb", "test/connections/native_db2", "test/connections/native_db2/connection.rb", "test/connections/native_firebird", "test/connections/native_firebird/connection.rb", "test/connections/native_frontbase", "test/connections/native_frontbase/connection.rb", "test/connections/native_mysql", "test/connections/native_mysql/connection.rb", "test/connections/native_openbase", "test/connections/native_openbase/connection.rb", "test/connections/native_oracle", "test/connections/native_oracle/connection.rb", "test/connections/native_postgresql", "test/connections/native_postgresql/connection.rb", "test/connections/native_sqlite", "test/connections/native_sqlite/connection.rb", "test/connections/native_sqlite3", "test/connections/native_sqlite3/connection.rb", "test/connections/native_sqlite3/in_memory_connection.rb", "test/connections/native_sybase", "test/connections/native_sybase/connection.rb", "test/fixtures", "test/fixtures/accounts.yml", "test/fixtures/all", "test/fixtures/all/developers.yml", "test/fixtures/all/people.csv", "test/fixtures/all/tasks.yml", "test/fixtures/author_addresses.yml", "test/fixtures/author_favorites.yml", "test/fixtures/authors.yml", "test/fixtures/binaries.yml", "test/fixtures/books.yml", "test/fixtures/categories", "test/fixtures/categories/special_categories.yml", "test/fixtures/categories/subsubdir", "test/fixtures/categories/subsubdir/arbitrary_filename.yml", "test/fixtures/categories.yml", "test/fixtures/categories_ordered.yml", "test/fixtures/categories_posts.yml", "test/fixtures/categorizations.yml", "test/fixtures/clubs.yml", "test/fixtures/comments.yml", "test/fixtures/companies.yml", "test/fixtures/computers.yml", "test/fixtures/courses.yml", "test/fixtures/customers.yml", "test/fixtures/developers.yml", "test/fixtures/developers_projects.yml", "test/fixtures/edges.yml", "test/fixtures/entrants.yml", "test/fixtures/faces.yml", "test/fixtures/fk_test_has_fk.yml", "test/fixtures/fk_test_has_pk.yml", "test/fixtures/funny_jokes.yml", "test/fixtures/interests.yml", "test/fixtures/items.yml", "test/fixtures/jobs.yml", "test/fixtures/legacy_things.yml", "test/fixtures/mateys.yml", "test/fixtures/member_types.yml", "test/fixtures/members.yml", "test/fixtures/memberships.yml", "test/fixtures/men.yml", "test/fixtures/minimalistics.yml", "test/fixtures/mixed_case_monkeys.yml", "test/fixtures/mixins.yml", "test/fixtures/movies.yml", "test/fixtures/naked", "test/fixtures/naked/csv", "test/fixtures/naked/csv/accounts.csv", "test/fixtures/naked/yml", "test/fixtures/naked/yml/accounts.yml", "test/fixtures/naked/yml/companies.yml", "test/fixtures/naked/yml/courses.yml", "test/fixtures/organizations.yml", "test/fixtures/owners.yml", "test/fixtures/parrots.yml", "test/fixtures/parrots_pirates.yml", "test/fixtures/people.yml", "test/fixtures/pets.yml", "test/fixtures/pirates.yml", "test/fixtures/posts.yml", "test/fixtures/price_estimates.yml", "test/fixtures/projects.yml", "test/fixtures/readers.yml", "test/fixtures/references.yml", "test/fixtures/reserved_words", "test/fixtures/reserved_words/distinct.yml", "test/fixtures/reserved_words/distincts_selects.yml", "test/fixtures/reserved_words/group.yml", "test/fixtures/reserved_words/select.yml", "test/fixtures/reserved_words/values.yml", "test/fixtures/ships.yml", "test/fixtures/sponsors.yml", "test/fixtures/subscribers.yml", "test/fixtures/subscriptions.yml", "test/fixtures/taggings.yml", "test/fixtures/tags.yml", "test/fixtures/tasks.yml", "test/fixtures/topics.yml", "test/fixtures/toys.yml", "test/fixtures/treasures.yml", "test/fixtures/vertices.yml", "test/fixtures/warehouse-things.yml", "test/fixtures/zines.yml", "test/migrations", "test/migrations/broken", "test/migrations/broken/100_migration_that_raises_exception.rb", "test/migrations/decimal", "test/migrations/decimal/1_give_me_big_numbers.rb", "test/migrations/duplicate", "test/migrations/duplicate/1_people_have_last_names.rb", "test/migrations/duplicate/2_we_need_reminders.rb", "test/migrations/duplicate/3_foo.rb", "test/migrations/duplicate/3_innocent_jointable.rb", "test/migrations/duplicate_names", "test/migrations/duplicate_names/20080507052938_chunky.rb", "test/migrations/duplicate_names/20080507053028_chunky.rb", "test/migrations/interleaved", "test/migrations/interleaved/pass_1", "test/migrations/interleaved/pass_1/3_innocent_jointable.rb", "test/migrations/interleaved/pass_2", "test/migrations/interleaved/pass_2/1_people_have_last_names.rb", "test/migrations/interleaved/pass_2/3_innocent_jointable.rb", "test/migrations/interleaved/pass_3", "test/migrations/interleaved/pass_3/1_people_have_last_names.rb", "test/migrations/interleaved/pass_3/2_i_raise_on_down.rb", "test/migrations/interleaved/pass_3/3_innocent_jointable.rb", "test/migrations/missing", "test/migrations/missing/1000_people_have_middle_names.rb", "test/migrations/missing/1_people_have_last_names.rb", "test/migrations/missing/3_we_need_reminders.rb", "test/migrations/missing/4_innocent_jointable.rb", "test/migrations/valid", "test/migrations/valid/1_people_have_last_names.rb", "test/migrations/valid/2_we_need_reminders.rb", "test/migrations/valid/3_innocent_jointable.rb", "test/models", "test/models/author.rb", "test/models/auto_id.rb", "test/models/binary.rb", "test/models/bird.rb", "test/models/book.rb", "test/models/categorization.rb", "test/models/category.rb", "test/models/citation.rb", "test/models/club.rb", "test/models/column_name.rb", "test/models/comment.rb", "test/models/company.rb", "test/models/company_in_module.rb", "test/models/computer.rb", "test/models/contact.rb", "test/models/contract.rb", "test/models/course.rb", "test/models/customer.rb", "test/models/default.rb", "test/models/developer.rb", "test/models/edge.rb", "test/models/entrant.rb", "test/models/essay.rb", "test/models/event.rb", "test/models/event_author.rb", "test/models/face.rb", "test/models/guid.rb", "test/models/interest.rb", "test/models/invoice.rb", "test/models/item.rb", "test/models/job.rb", "test/models/joke.rb", "test/models/keyboard.rb", "test/models/legacy_thing.rb", "test/models/line_item.rb", "test/models/man.rb", "test/models/matey.rb", "test/models/member.rb", "test/models/member_detail.rb", "test/models/member_type.rb", "test/models/membership.rb", "test/models/minimalistic.rb", "test/models/mixed_case_monkey.rb", "test/models/movie.rb", "test/models/order.rb", "test/models/organization.rb", "test/models/owner.rb", "test/models/parrot.rb", "test/models/person.rb", "test/models/pet.rb", "test/models/pirate.rb", "test/models/post.rb", "test/models/price_estimate.rb", "test/models/project.rb", "test/models/reader.rb", "test/models/reference.rb", "test/models/reply.rb", "test/models/ship.rb", "test/models/ship_part.rb", "test/models/sponsor.rb", "test/models/subject.rb", "test/models/subscriber.rb", "test/models/subscription.rb", "test/models/tag.rb", "test/models/tagging.rb", "test/models/task.rb", "test/models/topic.rb", "test/models/toy.rb", "test/models/treasure.rb", "test/models/vertex.rb", "test/models/warehouse_thing.rb", "test/models/zine.rb", "test/schema", "test/schema/mysql_specific_schema.rb", "test/schema/postgresql_specific_schema.rb", "test/schema/schema.rb", "test/schema/schema2.rb", "test/schema/sqlite_specific_schema.rb", "examples/associations.png", "examples/performance.rb"]
  s.homepage = %q{http://www.rubyonrails.org}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{activerecord}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Implements the ActiveRecord pattern for ORM.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, ["= 2.3.8"])
    else
      s.add_dependency(%q<activesupport>, ["= 2.3.8"])
    end
  else
    s.add_dependency(%q<activesupport>, ["= 2.3.8"])
  end
end
