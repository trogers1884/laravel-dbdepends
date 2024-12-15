# Laravel DB Depends

A Laravel package that creates a view for PostgreSQL database dependencies. This package helps you visualize and understand the relationships between tables, views, and materialized views in your PostgreSQL database by creating a comprehensive dependency map view.

## Overview

The package creates a view named `tr1884_dbdepends_vw_dependency_map` that shows:
- Direct and indirect dependencies between database objects
- Object ownership information
- Dependency counts and details
- Requirements for each database object

## Requirements

- PHP 8.1 or higher
- Laravel 10.x or 11.x
- PostgreSQL database

## Installation

1. Install the package via composer:
```bash
composer require trogers1884/laravel-dbdepends
```

2. The package will automatically register its service provider.

3. Run the migrations to create the dependency map view:
```bash
php artisan migrate
```

## Usage

Once installed, you can query the dependency map view like any other database view:

```php
use Illuminate\Support\Facades\DB;

// Get all view dependencies
$views = DB::table('tr1884_dbdepends_vw_dependency_map')
    ->where('object_type', 'VIEW')
    ->get();

// Find objects with the most dependencies
$mostDependencies = DB::table('tr1884_dbdepends_vw_dependency_map')
    ->orderByDesc('deps')
    ->limit(10)
    ->get();
```

### View Columns

The dependency map view includes the following columns:

| Column           | Type    | Description                               |
|-----------------|---------|-------------------------------------------|
| relation        | text    | Fully qualified name (schema.object_name) |
| object_type     | text    | TABLE, VIEW, or MATV (materialized view) |
| owner           | name    | Object owner's username                   |
| deps            | bigint  | Number of direct dependencies            |
| add_deps        | integer | Number of indirect dependencies          |
| reqs            | bigint  | Number of direct requirements            |
| add_reqs        | integer | Number of indirect requirements          |
| dependents      | text    | List of direct dependent objects         |
| add_dependents  | text    | List of indirect dependent objects       |
| requirements    | text    | List of direct required objects          |
| add_requirements| text    | List of indirect required objects        |

## Testing

To run the tests locally:

1. Copy the example PHPUnit configuration:
```bash
cp phpunit.xml.example phpunit.xml
```

2. Update `phpunit.xml` with your local PostgreSQL database credentials:
```xml
<env name="DB_HOST" value="your_host"/>
<env name="DB_PORT" value="5432"/>
<env name="DB_DATABASE" value="your_database"/>
<env name="DB_USERNAME" value="your_username"/>
<env name="DB_PASSWORD" value="your_password"/>
```

3. Run the tests:
```bash
./vendor/bin/phpunit
```

Note: `phpunit.xml` is git-ignored to prevent committing local database credentials.

## Complete Uninstallation

To completely remove the package from your Laravel application:

1. Drop the dependency map view from your database:
```sql
DROP VIEW IF EXISTS public.tr1884_dbdepends_vw_dependency_map;
```

2. Remove the migration record from your migrations table:
```sql
DELETE FROM migrations 
WHERE migration = '2024_01_01_000001_create_tr1884_dbdepends_vw_dependency_map_view';
```

3. Remove the package from your composer.json:
```bash
composer remove trogers1884/laravel-dbdepends
```

4. Remove any cached configuration:
```bash
php artisan config:clear
composer dump-autoload
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Clone your fork
3. Install dependencies:
```bash
composer install
```
4. Copy the test configuration files:
```bash
cp phpunit.xml.example phpunit.xml
cp .env.example .env.testing
```
5. Update both files with your PostgreSQL test database credentials
6. Run the tests to ensure everything is set up correctly:
```bash
./vendor/bin/phpunit
```

## Security

If you discover any security-related issues, please email [security contact] instead of using the issue tracker.

## Credits

- [Tom Rogers](https://github.com/trogers1884)
- [Jeremy Gleed](https://github.com/GITHUB_USERNAME)
- [All Contributors](../../contributors)

## License

The MIT License (MIT). Please see [License File](LICENSE) for more information.