import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createSummary from '@salesforce/apex/AF_AccountSummaryCreator.createSummary';

export default class AccountSummaryRecreateConfirm extends LightningElement {
    @api recordId;

    /**
     * Invoke method for headless Quick Action
     * This is called automatically when the action is triggered
     */
    @api invoke() {
        try {
            this.createSummaryRecord();
        } catch (error) {
            this.showToast('Error', 'Unexpected error: ' + (error.message || 'Unknown error'), 'error');
        }
    }

    /**
     * Creates the summary record (automatically deletes old ones if exist)
     */
    createSummaryRecord() {
        if (!this.recordId) {
            this.showToast('Error', 'Record ID is missing', 'error');
            return;
        }
        
        createSummary({ accountId: this.recordId })
            .then(result => {
                if (result) {
                    const response = result;
                    if (response.success) {
                        this.showToast('Success', response.message, 'success');
                    } else {
                        this.showToast('Error', response.message, 'error');
                    }
                } else {
                    this.showToast('Error', 'No response from server', 'error');
                }
            })
            .catch(error => {
                let errorMessage = 'Unknown error occurred';
                
                if (error.body) {
                    if (Array.isArray(error.body)) {
                        errorMessage = error.body.map(e => e.message).join('; ');
                    } else if (error.body.message) {
                        errorMessage = error.body.message;
                    } else if (typeof error.body === 'string') {
                        errorMessage = error.body;
                    }
                } else if (error.message) {
                    errorMessage = error.message;
                }
                
                this.showToast('Error', 'Error creating summary: ' + errorMessage, 'error');
            });
    }

    /**
     * Shows a toast message
     */
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}

