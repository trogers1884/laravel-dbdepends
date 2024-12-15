<?php

namespace Trogers1884\DBDepends;

use Illuminate\Support\ServiceProvider;

class DBDependsServiceProvider extends ServiceProvider
{
    public function boot()
    {
        if ($this->app->runningInConsole()) {
            $this->loadMigrationsFrom(__DIR__ . '/database/migrations');
        }
    }

    public function register()
    {
        // Register any bindings or services here if needed in the future
    }
}
