/*
    Configures the rest app along with basic exception handling and URL endpoints.
 */

package io.pleo.antaeus.rest

import io.javalin.Javalin
import io.javalin.apibuilder.ApiBuilder.get
import io.javalin.apibuilder.ApiBuilder.path
import io.javalin.apibuilder.ApiBuilder.post
import io.pleo.antaeus.core.exceptions.EntityNotFoundException
import io.pleo.antaeus.core.external.PaymentProvider
import io.pleo.antaeus.core.services.BillingService
import io.pleo.antaeus.core.services.CustomerService
import io.pleo.antaeus.core.services.InvoiceService
import io.pleo.antaeus.models.Invoice
import io.pleo.antaeus.models.Customer
import io.pleo.antaeus.models.Money
import mu.KotlinLogging

private val logger = KotlinLogging.logger {}

class AntaeusRest (
    private val invoiceService: InvoiceService,
    private val customerService: CustomerService,
    private val paymentProvider: PaymentProvider,
    private val port: Int
) : Runnable {

    override fun run() {
        app.start(this.port)
    }

    // Set up Javalin rest app
    private val app = Javalin
        .create()
        .apply {
            // InvoiceNotFoundException: return 404 HTTP status code
            exception(EntityNotFoundException::class.java) { _, ctx ->
                ctx.status(404)
            }
            // Unexpected exception: return HTTP 500
            exception(Exception::class.java) { e, ctx ->
                logger.error(e) { "Internal server error" }
                ctx.status(500)
            }
            // On 404: return message
            error(404) { ctx -> ctx.json("not found") }
        }

    // Pay all pending invoices
    // QUESTION: A bit of a strange logic to abort a batch job on
    // first error...
    private fun payInvoices(): Boolean {
        var didallsucceed: Boolean = true
        for (invoice:Invoice in invoiceService.fetchAllPending()) {
            println(invoice.toString())
            if (paymentProvider.charge(invoice)) {
                invoiceService.invoicePaid(invoice)
            } else {
                didallsucceed = false
            }
        }
        return didallsucceed
    }

    init {
        // Set up URL endpoints for the rest app
        app.routes {
           path("rest") {
               // Route to check whether the app is running
               // URL: /rest/health
               get("health") {
                   it.json("ok")
               }

               // V1
               path("v1") {
                   path("invoice") {
                       post {
                           val invoice = it.body<Invoice>()

                       }
                   }

                   path("invoices") {
                       // Attempt to pay invoices
                       post("pay") {
                           it.json(payInvoices())
                       }

                       // URL: /rest/v1/invoices
                       get {
                           it.json(invoiceService.fetchAll())
                       }

                       // URL: /rest/v1/invoices/{:id}
                       get(":id") {
                          it.json(invoiceService.fetch(it.pathParam("id").toInt()))
                       }
                   }

                   path("customers") {
                       // URL: /rest/v1/customers
                       get {
                           it.json(customerService.fetchAll())
                       }

                       // URL: /rest/v1/customers/{:id}
                       get(":id") {
                           it.json(customerService.fetch(it.pathParam("id").toInt()))
                       }
                   }

               }
           }
        }
    }
}
