<?php

namespace Trogers1884\DBDepends\Tests;

use Orchestra\Testbench\TestCase as Orchestra;
use Trogers1884\DBDepends\DBDependsServiceProvider;

class TestCase extends Orchestra
{
    protected function defineEnvironment($app)
    {
        // Load .env.testing file if it exists
        if (file_exists(__DIR__ . '/../.env.testing')) {
            $dotenv = \Dotenv\Dotenv::createImmutable(__DIR__ . '/..', '.env.testing');
            $dotenv->load();
        }
    }

    protected function getPackageProviders($app)
    {
        return [
            DBDependsServiceProvider::class,
        ];
    }

    protected function defineDatabaseMigrations()
    {
        $this->loadMigrationsFrom(__DIR__ . '/../src/database/migrations');
    }

    protected function getEnvironmentSetUp($app)
    {
        // Setup default database to use postgresql with no default credentials
        $app['config']->set('database.default', 'pgsql');
        $app['config']->set('database.connections.pgsql', [
            'driver' => 'pgsql',
            'host' => env('DB_HOST'),
            'port' => env('DB_PORT', '5432'),
            'database' => env('DB_DATABASE'),
            'username' => env('DB_USERNAME'),
            'password' => env('DB_PASSWORD'),
            'charset' => 'utf8',
            'prefix' => '',
            'prefix_indexes' => true,
            'schema' => 'public',
            'sslmode' => 'prefer',
        ]);
    }
}