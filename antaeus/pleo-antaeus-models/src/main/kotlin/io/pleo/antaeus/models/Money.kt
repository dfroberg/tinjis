package io.pleo.antaeus.models

import java.math.BigDecimal
import io.pleo.antaeus.models.Currency

data class Money(
    val value: BigDecimal,
    val currency: Currency
)
