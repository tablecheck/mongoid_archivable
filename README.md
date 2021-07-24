# Mongoid::Archivable

[![Build Status](https://travis-ci.org/tablecheck/mongoid_archivable.svg?branch=master)](https://travis-ci.org/simi/mongoid_archivable) [![Gem Version](https://img.shields.io/gem/v/mongoid_archivable.svg)](https://rubygems.org/gems/mongoid_archivable) [![Gitter chat](https://badges.gitter.im/tablecheck/mongoid_archivable.svg)](https://gitter.im/tablecheck/mongoid_archivable)

`Mongoid::Archivable` enables archiving (soft delete) of Mongoid documents. Instead of being removed from the database, archived docs are flagged with an `archived_at` timestamp. This gem is forked from [mongoid_paranoia](https://github.com/simi/mongoid_paranoia).

**Caution:** This repo/gem `mongoid_archivable` (underscored) is different than [mongoid-archivable](https://github.com/Sign2Pay/mongoid-archivable) (hyphenated).

#### Differences with Mongoid::Paranoia

Note the following key design differences:

* The flag named is `archived_at` rather than `deleted_at`. The name `deleted_at` is confusing with respect to hard deletion.
* This gem does **not** set a default scope on root (non-embedded) docs. Use the `.unarchived` (live) and `.archived` query scopes as needed.
* Mongoid::Paranoia overrides the `delete` and `destroy` methods with new "soft-delete" behavior. This gem leaves `delete` and `destroy` intact.
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

person.delete   # Sets the archived_at field to the current time, ignoring callbacks.
person.delete!  # Permanently deletes the document, ignoring callbacks.
person.destroy  # Sets the archived_at field to the current time, firing callbacks.
person.destroy! # Permanently deletes the document, firing callbacks.

person.archive  # Sets the archived_at field to the current time, firing callbacks.

# TODO
person.archive(callbacks: false) # Sets the archived_at field to the current time, ignoring callbacks.

person.restore # Brings the "archived" document back to life.

person.restore(recursive: true) # Brings "archived" associated documents back to life recursively
```

#### Querying

```ruby
Person.all # Returns all documents, both archived and non-archived

Person.unarchived # Returns documents that have been "flagged" as archived.

Person.archived # Returns documents that have been "flagged" as archived.
```

#### Configuration

You can configure the archivable field naming on a global basis. Within the context of a Rails app this is done via an initializer.

```ruby
# config/initializers/mongoid_archivable.rb

Mongoid::Archivable.configure do |c|
  c.archivable_field = :my_field_name
end
```

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

### Callbacks

Archivable documents have the following new callbacks:

* `before_archive`
* `after_archive`
* `around_archive`
* `before_restore`
* `after_restore`
* `around_restore`

#### Example

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
end
```

## Migrating from Mongoid::Paranoia

1. Add `mongoid_archivable` to your gemspec **after** `mongoid_paranoia`
2. Define your archived field name as `:deleted_at` for backwards compatibility.
3. Add `.unarchived` to your queries as necessary. You can remove usages of `.unscoped`.

Note that it is possible to migrate each model individually.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
