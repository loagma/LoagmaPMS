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
        if (Schema::hasTable('suppliers')) {
            if (! Schema::hasTable('supplier_products')) {
                Schema::create('supplier_products', function (Blueprint $table) {
                    $this->supplierProductsTable($table);
                });
            }
            return;
        }

        Schema::create('suppliers', function (Blueprint $table) {
            $table->id();
            $table->string('supplier_code', 50)->unique();
            $table->string('name', 255);
            $table->string('legal_name', 255)->nullable();
            $table->string('business_type', 100)->nullable();
            $table->string('industry', 150)->nullable();
            $table->string('gstin', 20)->nullable()->index();
            $table->string('pan', 20)->nullable()->index();
            $table->string('tan', 20)->nullable();
            $table->string('cin', 30)->nullable();
            $table->string('vat_number', 30)->nullable();
            $table->string('registration_number', 50)->nullable();

            $table->string('website', 255)->nullable();
            $table->string('email', 255)->nullable();
            $table->string('phone', 30)->nullable();
            $table->string('alternate_phone', 30)->nullable();
            $table->string('fax', 30)->nullable();

            $table->string('contact_person', 255)->nullable();
            $table->string('contact_person_email', 255)->nullable();
            $table->string('contact_person_phone', 30)->nullable();
            $table->string('contact_person_designation', 100)->nullable();

            $table->string('billing_address_line1', 255)->nullable();
            $table->string('billing_address_line2', 255)->nullable();
            $table->string('billing_city', 100)->nullable();
            $table->string('billing_state', 100)->nullable();
            $table->string('billing_country', 100)->nullable();
            $table->string('billing_postal_code', 20)->nullable();

            $table->string('shipping_address_line1', 255)->nullable();
            $table->string('shipping_address_line2', 255)->nullable();
            $table->string('shipping_city', 100)->nullable();
            $table->string('shipping_state', 100)->nullable();
            $table->string('shipping_country', 100)->nullable();
            $table->string('shipping_postal_code', 20)->nullable();

            $table->string('bank_name', 150)->nullable();
            $table->string('bank_branch', 150)->nullable();
            $table->string('bank_account_name', 150)->nullable();
            $table->string('bank_account_number', 50)->nullable();
            $table->string('ifsc_code', 20)->nullable();
            $table->string('swift_code', 20)->nullable();

            $table->unsignedSmallInteger('payment_terms_days')->nullable();
            $table->decimal('credit_limit', 12, 2)->nullable();
            $table->decimal('rating', 3, 2)->nullable();
            $table->boolean('is_preferred')->default(false);
            $table->enum('status', ['ACTIVE', 'INACTIVE', 'SUSPENDED'])->default('ACTIVE');

            $table->text('notes')->nullable();
            $table->json('metadata')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();

            $table->timestamps();
            $table->softDeletes();
        });

        if (! Schema::hasTable('supplier_products')) {
            Schema::create('supplier_products', function (Blueprint $table) {
                $this->supplierProductsTable($table);
            });
        }
    }

    private function supplierProductsTable(Blueprint $table): void
    {
        $table->id();
        $table->unsignedBigInteger('supplier_id');
        $table->unsignedBigInteger('product_id');

        $table->string('supplier_sku', 100)->nullable();
        $table->string('supplier_product_name', 255)->nullable();
        $table->text('description')->nullable();

        $table->decimal('pack_size', 10, 3)->nullable();
        $table->string('pack_unit', 20)->nullable();
        $table->decimal('min_order_qty', 12, 3)->nullable();

        $table->decimal('price', 12, 2)->nullable();
        $table->string('currency', 3)->nullable();
        $table->decimal('tax_percent', 5, 2)->nullable();
        $table->decimal('discount_percent', 5, 2)->nullable();
        $table->unsignedSmallInteger('lead_time_days')->nullable();

        $table->decimal('last_purchase_price', 12, 2)->nullable();
        $table->date('last_purchase_date')->nullable();

        $table->boolean('is_preferred')->default(false);
        $table->boolean('is_active')->default(true);

        $table->text('notes')->nullable();
        $table->json('metadata')->nullable();

        $table->timestamps();

        $table->foreign('supplier_id')
            ->references('id')
            ->on('suppliers')
            ->onDelete('cascade');

        $table->foreign('product_id')
            ->references('product_id')
            ->on('product');

        $table->unique(['supplier_id', 'supplier_sku']);
        $table->index(['supplier_id', 'product_id']);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('supplier_products');
        Schema::dropIfExists('suppliers');
    }
};
