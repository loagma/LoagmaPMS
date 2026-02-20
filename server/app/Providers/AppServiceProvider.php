<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Register stock management services
        $this->app->singleton(\App\Services\UnitConverter::class);
        $this->app->singleton(\App\Services\PackJsonManager::class);
        $this->app->singleton(\App\Services\StockAuditLogger::class);
        
        $this->app->singleton(\App\Services\PackSynchronizer::class, function ($app) {
            return new \App\Services\PackSynchronizer(
                $app->make(\App\Services\UnitConverter::class)
            );
        });
        
        $this->app->singleton(\App\Services\ProductStockAggregator::class, function ($app) {
            return new \App\Services\ProductStockAggregator(
                $app->make(\App\Services\UnitConverter::class),
                $app->make(\App\Services\PackJsonManager::class)
            );
        });
        
        $this->app->singleton(\App\Services\StockManagerService::class, function ($app) {
            return new \App\Services\StockManagerService(
                $app->make(\App\Services\UnitConverter::class),
                $app->make(\App\Services\PackSynchronizer::class),
                $app->make(\App\Services\PackJsonManager::class),
                $app->make(\App\Services\ProductStockAggregator::class),
                $app->make(\App\Services\StockAuditLogger::class)
            );
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
