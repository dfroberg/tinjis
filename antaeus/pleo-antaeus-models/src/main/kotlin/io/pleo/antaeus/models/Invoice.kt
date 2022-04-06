package io.pleo.antaeus.models


import io.pleo.antaeus.models.InvoiceStatus
import io.pleo.antaeus.models.Money

data class Invoice(
    val id: Int,
    val customerId: Int,
    val amount: Money,
    val status: InvoiceStatus
)
