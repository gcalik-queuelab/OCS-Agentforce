import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getRecommendations from '@salesforce/apex/AF_NPSCreateActionsController.getRecommendations';
import createActionsFromRecommendations from '@salesforce/apex/AF_NPSCreateActionsController.createActionsFromRecommendations';

export default class NpsCreateActionsFromSummary extends LightningElement {
    @api recordId; // NPS_Survey_Summary__c record ID

    recommendations = [];
    selectedRecommendations = [];
    isModalOpen = false;
    isLoading = false;
    wiredRecommendationsResult;

    /**
     * Wire to get recommendations
     */
    @wire(getRecommendations, { summaryId: '$recordId' })
    wiredRecommendations(result) {
        this.wiredRecommendationsResult = result;
        if (result.data) {
            // Add index and checked properties to each recommendation
            this.recommendations = result.data.map((rec, index) => ({
                ...rec,
                index: index,
                checked: false,
                id: `rec-${index}` // Unique ID for checkbox
            }));
        } else if (result.error) {
            this.showToast('Error', 'Failed to load recommendations: ' + this.getErrorMessage(result.error), 'error');
        }
    }

    /**
     * Check if there are recommendations
     */
    get hasRecommendations() {
        return this.recommendations && this.recommendations.length > 0;
    }

    /**
     * Check if any recommendations are selected
     */
    get hasSelectedRecommendations() {
        return this.selectedRecommendations && this.selectedRecommendations.length > 0;
    }

    /**
     * Get button label with count
     */
    get createButtonLabel() {
        if (this.hasSelectedRecommendations) {
            return `Create ${this.selectedRecommendations.length} Action${this.selectedRecommendations.length > 1 ? 's' : ''}`;
        }
        return 'Create Actions';
    }

    /**
     * Opens the modal dialog
     */
    handleOpenModal() {
        if (!this.hasRecommendations) {
            this.showToast('No Recommendations', 'No recommendations available to create actions from. Please regenerate the summary.', 'warning');
            return;
        }
        this.isModalOpen = true;
    }

    /**
     * Closes the modal dialog
     */
    handleCloseModal() {
        this.isModalOpen = false;
        // Reset selections
        this.recommendations = this.recommendations.map(rec => ({
            ...rec,
            checked: false
        }));
        this.selectedRecommendations = [];
    }

    /**
     * Handles checkbox change
     */
    handleCheckboxChange(event) {
        const index = parseInt(event.target.dataset.index);
        const isChecked = event.target.checked;

        // Update the recommendation's checked status
        this.recommendations = this.recommendations.map(rec => {
            if (rec.index === index) {
                return { ...rec, checked: isChecked };
            }
            return rec;
        });

        // Update selected recommendations
        this.updateSelectedRecommendations();
    }

    /**
     * Updates the list of selected recommendation indices
     */
    updateSelectedRecommendations() {
        this.selectedRecommendations = this.recommendations
            .filter(rec => rec.checked)
            .map(rec => rec.index);
    }

    /**
     * Handles the create actions button click
     */
    async handleCreateActions() {
        if (!this.hasSelectedRecommendations) {
            this.showToast('No Selection', 'Please select at least one recommendation', 'warning');
            return;
        }

        this.isLoading = true;

        try {
            const result = await createActionsFromRecommendations({
                summaryId: this.recordId,
                selectedIndices: this.selectedRecommendations
            });

            if (result.success) {
                this.showToast('Success', result.message, 'success');
                this.handleCloseModal();

                // Refresh the page to show the new actions
                setTimeout(() => {
                    eval("$A.get('e.force:refreshView').fire();");
                }, 1000);
            } else {
                this.showToast('Error', result.message, 'error');
            }

        } catch (error) {
            this.showToast('Error', 'Failed to create actions: ' + this.getErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Extracts error message from error object
     */
    getErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        } else if (error.message) {
            return error.message;
        } else if (typeof error === 'string') {
            return error;
        }
        return 'Unknown error occurred';
    }

    /**
     * Shows a toast notification
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}
