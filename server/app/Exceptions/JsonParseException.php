<?php

namespace App\Exceptions;

use Exception;

class JsonParseException extends Exception
{
    protected $message = 'Failed to parse JSON data';
    protected $code = 500;

    public function __construct(string $message = 'Failed to parse JSON data')
    {
        parent::__construct($message, 500);
    }
}
