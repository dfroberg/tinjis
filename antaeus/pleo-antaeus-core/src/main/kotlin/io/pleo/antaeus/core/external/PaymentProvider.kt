/*
    This is the payment provider. It is a "mock" of an external service that you can pretend runs on another system.
    With this API you can ask customers to pay an invoice.

    This mock will succeed if the customer has enough money in their balance,
    however the documentation lays out scenarios in which paying an invoice could fail.
 */

package io.pleo.antaeus.core.external

import io.pleo.antaeus.core.services.InvoiceService
import io.pleo.antaeus.models.Invoice
import io.pleo.antaeus.models.InvoiceStatus
import io.pleo.antaeus.models.Customer
import io.pleo.antaeus.models.Currency
import io.pleo.antaeus.models.Money

class PaymentProvider(
        private val paymentProviderRestEndpoint: String,
        private val paymentProviderRestEndpointToken: String,
        private val invoiceService: InvoiceService
) {
    /*
        Charge a customer's account the amount from the invoice.

        Returns:
          `True` when the customer account was successfully charged the given amount.
          `False` when the customer account balance did not allow the charge.

        Throws:
          `CustomerNotFoundException`: when no customer has the given id.
          `CurrencyMismatchException`: when the currency does not match the customer account.
          `NetworkException`: when a network error happens.
     */

    fun charge(invoice: Invoice): Boolean {
        // Have no idea why but this works as the mapped enum values aren't properly unpacked here
        // I'm not a java or kotlin guy so pardon the mess.
        return khttp
                .post(  url = this.paymentProviderRestEndpoint,
                        headers = mapOf(
                                "X-Token" to this.paymentProviderRestEndpointToken
                        ),
                        json = mapOf(
                                "value" to invoice.amount.value,
                                "currency" to invoice.amount.currency.toString(),
                                "customer_id" to invoice.customerId
                        )
                )
                .jsonObject.getBoolean("result")
    }
}
