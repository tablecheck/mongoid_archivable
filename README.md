# Mongoid::Archivable

[![Build Status](https://github.com/tablecheck/mongoid_archivable/actions/workflows/test.yml/badge.svg?query=branch%3Amaster)](https://github.com/tablecheck/mongoid_archivable/actions/workflows/test.yml?query=branch%3Amaster)
[![Gem Version](https://img.shields.io/gem/v/mongoid_archivable.svg)](https://rubygems.org/gems/mongoid_archivable)

`Mongoid::Archivable` enables archiving (soft delete) of Mongoid documents.
Instead of being removed from the database, archived docs are flagged with an `archived_at` timestamp.
This allows you to maintain references to archived documents, and restore if necessary.

#### Instability Warning

Versions prior to 1.0.0 are in **alpha** state. Behaviors, APIs, method names, etc.
may change anytime without warning. Please lock your gem version, be careful when upgrading,
and write tests in your own project.

#### Disambiguation

* This gem is forked from [mongoid_paranoia](https://github.com/simi/mongoid_paranoia).
See section below for key differences.
* This gem is different than [mongoid-archivable](https://github.com/Sign2Pay/mongoid-archivable)
(hyphenated), which moves documents to a separate "archive" database/collection.

#### TODO

* [ ] Support embedded documents.
* [ ] Support model-level configuration.
* [ ] Allow rename archive field alias.
* [ ] Consider adding #archive(callbacks: false)
* [ ] Consider adding .archive_all query action

## Usage

#### Installation

In your application's Gemfile:

```ruby
gem 'mongoid_archivable'
```

#### Adding to Model Class

```ruby
class Person
  include Mongoid::Document
  include Mongoid::Archivable

  # TODO: archivable
end
```

#### Archiving with Documents

```ruby
# Set the archived_at field to the current time, firing callbacks
# and archiving any dependent documents. Analogous to Mongoid #destroy method.
person.archive

# Sets the archived_at field to the current time, ignoring callbacks
# and dependency rules. Analogous to Mongoid #delete method.
person.archive_without_callbacks
# TODO person.archive(callbacks: false)

# Un-archive an archive document back.
person.restore

# Un-archive an archive document back, including any dependent documents.
person.restore(recursive: true)
```

#### Querying

```ruby
# Return all documents, both archived and non-archived.
Person.all

# Return only documents that are not flagged as archived.
Person.current

# Return only documents that are flagged as archived.
Person.archived
```

#### Global Configuration

You may globally configure field and method names in an initializer.

```ruby
# config/initializers/mongoid_archivable.rb

Mongoid::Archivable.configure do |c|
  c.archived_field = :archived_at
  c.archived_scope = :archived
  c.nonarchived_scope = :current
end
```

#### Callbacks

Archivable documents have the following new callbacks.
Note that these callbacks are **not** fired on `#destroy`.

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

  # You may `throw(:abort)` within a callback to prevent
  # the action from proceeding.
  def before_archive_action
    throw(:abort) if name == 'Pete'
  end
end
```

#### Relation Dependencies

This gem adds two new relation dependency handling strategies:

* `:archive` - Invokes `#archive` and callbacks on each dependency, recursively
including dependencies of dependencies. Analogous to `:destroy`.
* `:archive_all` - Calls `.set(archived_at: Time.now)` on the
dependency scope in a single query. Much faster but does not support callbacks
or dependency recursion. Analogous to `:delete_all`.

If the dependent model is not archivable, these strategies will be ignored without any effect.

```ruby
class User
  include Mongoid::Document
  include Mongoid::Archivable

  has_many :pokemons, dependent: :archive
  belongs_to :gym, dependent: :archive_all
end
```

In addition, dependency strategies `:nullify`, `:restrict_with_exception`,
and `:restrict_with_error` will be applied when archiving documents.
`:destroy` and `:delete_all` are intentionally ignored.

#### Protecting Against Deletion

Add the `Mongoid::Archivable::Protected` mixin to cause 
`#delete` and `#destroy` methods to raise an error.
The bang methods `#delete!` and `#destroy!` can be used instead.
This is useful when migrating a legacy codebase.

```ruby
class Pokemon
  include Mongoid::Document
  include Mongoid::Archivable
  include Mongoid::Archivable::Protected
end

venusaur = Pokemon.create
venusaur.delete    # raises RuntimeError
venusaur.destroy   # raises RuntimeError
venusaur.delete!   # deletes the document without callbacks
venusaur.destroy!  # deletes the document with callbacks
```

## Gotchas

The following require additional manual changes when using this gem.

#### Uniqueness Validation

You must set `scope: :archived_at` in your uniqueness validations to prevent
validating against archived documents.

```ruby
validates_uniqueness_of :title, scope: :archived_at
```

#### Indexes

You should add `archived_at` to your query indexes. As a rule-of-thumb, we recommend
to add `archived_at` as the final key; this will create a compound index that will be
selected with or without `archived_at` in the query.

```ruby
index category: 1, title: 1, archived_at: 1
```

Note that this may not give the best performance in all cases, for example
when performing a time-range query on the value of `archived_at`. Please refer to the
[MongoDB Indexes documentation](https://docs.mongodb.com/manual/indexes/)
to learn more about index design.

## Comparison with Mongoid::Paranoia

We used [Mongoid::Paranoia](https://github.com/simi/mongoid_paranoia) at [TableCheck](https://www.tablecheck.com/en/join/)
for many years. While many of design assumptions of Mongoid::Paranoia
lead to initial productivity, we found them ultimately limiting and unintuitive
as we grew both our team and our codebase.

#### Key Differences 

* The flag named is `archived_at` rather than `deleted_at`.
The name `deleted_at` was confusing with respect to hard deletion.
* Mongoid::Paranoia overrides the `#delete` and `#destroy` methods; this gem does not.
Monkey patches and hackery are removed; behavior is less surprising.
* This gem does **not** set a default scope on root (non-embedded) docs.
Use the `.current` (non-archived) and `.archived` query scopes as needed.
Mongoid::Paranoia relies on `.unscoped` 

#### Migration Checklist

* [ ] Add `mongoid_archivable` to your gemspec **after** `mongoid_paranoia`.
You may use the two gems together in your project,
but should include only one of `Mongoid::Archivable` or `Mongoid::Paranoia` into each model class.
In this manner, you can migrate each model one-by-one.
* [ ] To avoid accidentally calling `#delete` and `#destroy`, add the
`Mongoid::Archivable::Protected` mixin to cause those methods to raise an error.
* [ ] Configure your `archived_field_name = :deleted_at` for backwards compatibility.
* [ ] Add `.current` to your queries as necessary. You can remove usages of `.unscoped`.
* [ ] In your relations, replace `dependent: :destroy` with `dependent: :archive` as necessary.

## About Us

Mongoid::Archivable is made with ❤ by [TableCheck](https://www.tablecheck.com/en/join/),
the leading restaurant reservation and guest management app maker.
If **you** are a ninja-level 🥷 coder (Javascript/Ruby/Elixir/Python/Go),
designer, product manager, data scientist, QA, etc. and are ready to join us in Tokyo, Japan
or work remotely, please get in touch at [careers@tablecheck.com](mailto:careers@tablecheck.com).

Shout out to Durran Jordan and Josef Šimánek for their original work on
[Mongoid::Paranoia](https://github.com/simi/mongoid_paranoia).
