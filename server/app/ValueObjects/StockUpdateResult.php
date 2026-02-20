<?php

namespace App\ValueObjects;

/**
 * StockUpdateResult Value Object
 * 
 * Represents the result of a stock update operation.
 */
class StockUpdateResult
{
    public bool $success;
    public string $message;
    /** @var PackStockUpdate[] */
    public array $packUpdates;
    public ?array $errors;

    /**
     * @param PackStockUpdate[] $packUpdates
     */
    public function __construct(
        bool $success,
        string $message,
        array $packUpdates = [],
        ?array $errors = null
    ) {
        $this->success = $success;
        $this->message = $message;
        $this->packUpdates = $packUpdates;
        $this->errors = $errors;
    }

    /**
     * Create a successful result
     * 
     * @param PackStockUpdate[] $packUpdates
     */
    public static function success(string $message, array $packUpdates): self
    {
        return new self(
            success: true,
            message: $message,
            packUpdates: $packUpdates,
            errors: null
        );
    }

    /**
     * Create a failure result
     */
    public static function failure(string $message, array $errors = []): self
    {
        return new self(
            success: false,
            message: $message,
            packUpdates: [],
            errors: $errors
        );
    }

    /**
     * Convert to array for JSON serialization
     */
    public function toArray(): array
    {
        return [
            'success' => $this->success,
            'message' => $this->message,
            'pack_updates' => array_map(fn($update) => $update->toArray(), $this->packUpdates),
            'errors' => $this->errors,
        ];
    }
}
