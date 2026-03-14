<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Creates categories table for product module.
 * Category: parent_cat_id = 0. Subcategory: parent_cat_id = parent's cat_id.
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (! Schema::hasTable('categories')) {
            Schema::create('categories', function (Blueprint $table) {
                $table->bigIncrements('cat_id');
                $table->string('name', 250);
                $table->unsignedInteger('parent_cat_id');
                $table->unsignedTinyInteger('is_active')->default(0);
                $table->tinyInteger('type')->default(0)->comment('0: Has subcategories, 1: Has products');
                $table->string('image_slug', 15)->default(' ');
                $table->text('image_name')->nullable();
                $table->unsignedInteger('img_last_updated')->default(0);
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
