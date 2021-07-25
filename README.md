# Mongoid::Archivable

[![Build Status](https://travis-ci.org/tablecheck/mongoid_archivable.svg?branch=master)](https://travis-ci.org/simi/mongoid_archivable) [![Gem Version](https://img.shields.io/gem/v/mongoid_archivable.svg)](https://rubygems.org/gems/mongoid_archivable)

`Mongoid::Archivable` enables archiving (soft delete) of Mongoid documents. Instead of being removed from the database, archived docs are flagged with an `archived_at` timestamp. This gem is forked from [mongoid_paranoia](https://github.com/simi/mongoid_paranoia).

Note that this gem `mongoid_archivable` (underscored) is different than [mongoid-archivable](https://github.com/Sign2Pay/mongoid-archivable) (hyphenated).

#### Differences with Mongoid::Paranoia

* The flag named is `archived_at` rather than `deleted_at`. The name `deleted_at` is confusing with respect to hard deletion.
* This gem does **not** set a default scope on root (non-embedded) docs. Use the `.unarchived` (live) and `.archived` query scopes as needed.
* Mongoid::Paranoia overrides the `delete` and `destroy` methods with new "soft-delete" behavior. This gem leaves `delete` and `destroy` as-is.
* Requires calling the `archivable` macro function in the model definition to enable. Model-specific configuration is possible.
* Monkey patches and hackery are removed.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mongoid_archivable'
```

## Usage

```ruby
class Person
  include Mongoid::Document
  include Mongoid::Archivable

  # TODO
  archivable
end

person.archive  # Sets the archived_at field to the current time, firing callbacks.

# TODO
person.archive(callbacks: false) # Sets the archived_at field to the current time, ignoring callbacks.

person.restore # Brings the "archived" document back to life.

person.restore(recursive: true) # Brings "archived" associated documents back to life recursively
```

#### Configuration

You can configure the archivable field naming on a global basis. Within the context of a Rails app this is done via an initializer.

```ruby
# config/initializers/mongoid_archivable.rb

Mongoid::Archivable.configure do |c|
  c.archivable_field = :my_field_name
end
```

#### Querying

```ruby
Person.all # Returns all documents, both archived and non-archived

Person.unarchived # Returns documents that have been "flagged" as archived.

Person.archived # Returns documents that have been "flagged" as archived.
```

#### Callbacks

Archivable documents have the following new callbacks. Note that these are **not** fired on `#destroy`.

* `before_archive`
* `after_archive`
* `around_archive`
* `before_restore`
* `after_restore`
* `around_restore`

```ruby
class User
  include Mongoid::Document
  include Mongoid::Archivable

  before_archive :before_archive_action
  after_archive :after_archive_action
  around_archive :around_archive_action

  before_restore :before_restore_action
  after_restore :after_restore_action
  around_restore :around_restore_action

  def before_archive_action
    throw(:abort) if name == 'Pete'
  end
end
```

#### Relation Dependencies

This gem add two new dependency handling strategies:

* `:archive` - Invokes `#archive` and callbacks on each dependency, recursively
including dependencies of dependencies.
* `:archive_without_callbacks` - Calls `.set(archived_at: Time.now)` on the
dependency scope. Much faster but does not support callbacks or dependency recursion.

```
class User
  include Mongoid::Document
  include Mongoid::Archivable

  has_many :pokemons, dependent: :archive
  belongs_to :gym, dependent: :archive_without_callbacks
end
```

If the dependent model is not archivable, it will be ignored without any effect.

In addition, dependency strategies `:nullify`, `:restrict_with_exception`,
and `:restrict_with_error` will be applied when archiving documents.
`:destroy` and `:delete_all` are intentionally ignored.

### Gotchas

#### Uniqueness validations

Set `scope: :archived_at` in your uniqueness validations to prevent validating against archived documents.

```ruby
validates_uniqueness_of :title, scope: :archived_at
```

#### Indexes

Be sure to add `archived_at` to your query indexes. As a rule-of-thumb, we recommend
to add `archived_at` as the final key; this will create a compound index that will work
with or without `archived_at` in the query.

```ruby
index category: 1, title: 1, archived_at: 1
```

Note that this may not give the best performance in all cases, e.g. when doing a range query
on the value of `archived_at`, so please refer to the
[MongoDB Indexes documentation](https://docs.mongodb.com/manual/indexes/).

## Mongoid::Paranoia Migration Checklist

1. Add `mongoid_archivable` to your gemspec **after** `mongoid_paranoia`
2. Configure your archived field name as `:deleted_at` for backwards compatibility.
3. Add `.unarchived` to your queries as necessary. You can remove usages of `.unscoped`.
4. In your relations, replace `dependent: :destroy` with `dependent: :archive`

Note that it is possible to migrate each model individually.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
