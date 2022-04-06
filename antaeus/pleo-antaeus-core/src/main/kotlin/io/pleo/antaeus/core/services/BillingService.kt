package io.pleo.antaeus.core.services

import io.pleo.antaeus.core.external.PaymentProvider
import io.pleo.antaeus.models.Invoice

class BillingService
 {
    fun charge(invoice: Invoice): Boolean {
        return true
    }
}
