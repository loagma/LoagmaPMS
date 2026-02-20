<?php

namespace App\Exceptions;

use Exception;

class VendorProductNotFoundException extends Exception
{
    protected $message = 'Vendor product not found';
    protected $code = 404;

    public function __construct(int $vendorProductId)
    {
        parent::__construct("Vendor product with ID {$vendorProductId} not found", 404);
    }
}
