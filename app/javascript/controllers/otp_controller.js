import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="otp"
export default class extends Controller {
    static targets = ["input"]

    connect() {
        if ('OTPCredential' in window) {
            const form = this.inputTarget.closest('form')
            const ac = new AbortController()

            form.addEventListener('submit', () => {
                ac.abort() // Abort OTP detection if form is submitted manually
            })

            navigator.credentials.get({
                otp: {transport: ['sms']},
                signal: ac.signal
            }).then(otp => {
                this.inputTarget.value = otp.code

                form.submit()
            }).catch(err => {
                if (err.name !== 'AbortError') {
                    console.log('WebOTP Error:', err)
                }
            })
        }
    }
}
