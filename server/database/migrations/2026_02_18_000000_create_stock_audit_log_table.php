<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Optional Migration: Stock Audit Log Table
 * 
 * This migration creates a dedicated database table for stock audit logs.
 * 
 * NOTE: This is an OPTIONAL migration. The system currently uses Laravel's
 * file-based logging system via the StockAuditLogger service. This migration
 * provides an alternative structured storage option for audit data.
 * 
 * Benefits of using this table:
 * - Better queryability for audit reports
 * - Structured data for analytics
 * - Easier filtering and searching
 * - Long-term retention management
 * 
 * To use this table instead of file logs, update the StockAuditLogger service
 * to write to this table instead of using Log::channel('stock_audit').
 * 
 * Requirements: 10.1, 10.2, 10.3, 10.5
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('stock_audit_log', function (Blueprint $table) {
            // Primary key
            $table->id();
            
            // Core identifiers
            $table->integer('vendor_product_id')->index();
            $table->string('trigger_pack_id', 255)->index();
            
            // Stock update details (JSON format)
            // Structure: [{"pack_id": "...", "old_stock": 10, "new_stock": 15, "change": 5}, ...]
            $table->json('pack_updates');
            
            // Audit metadata
            $table->string('reason', 500);
            $table->integer('user_id')->nullable()->index();
            
            // Timestamps
            $table->timestamp('created_at')->useCurrent();
            
            // Indexes for common queries
            $table->index('created_at');
            $table->index(['vendor_product_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('stock_audit_log');
    }
};
