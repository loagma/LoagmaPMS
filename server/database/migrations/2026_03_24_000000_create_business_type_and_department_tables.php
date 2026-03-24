<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (! Schema::hasTable('BusinessType')) {
            Schema::create('BusinessType', function (Blueprint $table) {
                $table->string('id', 10)->primary();
                $table->string('name', 100);
                $table->timestamp('createdAt', 3)->useCurrent();
            });
        }

        if (! Schema::hasTable('Department')) {
            Schema::create('Department', function (Blueprint $table) {
                $table->string('id', 10)->primary();
                $table->string('name', 100);
                $table->timestamp('createdAt', 3)->nullable()->useCurrent();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('Department');
        Schema::dropIfExists('BusinessType');
    }
};
