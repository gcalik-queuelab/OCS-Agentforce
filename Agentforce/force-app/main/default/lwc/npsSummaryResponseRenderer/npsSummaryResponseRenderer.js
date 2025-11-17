/**
 * @description NPS Survey Summary single record renderer for Agentforce
 * Based on npsSurveyListRenderer but adapted for single summary record display
 */
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NpsSummaryResponseRenderer extends NavigationMixin(LightningElement) {
    
    summaryData = null;

    @api
    get value() {
        return this._value;
    }
    
    /**
     * @param  {NPSSummaryItem} value - The NPS summary data from Apex
     */
    set value(value) {
        this._value = value;
    }

    /**
     * @description Handle summary click to navigate to summary record
     * @param {Event} event - Click event
     */
    handleSummaryClick(event) {
        const summaryId = event.currentTarget.dataset.summaryId;
        
        if (summaryId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: summaryId,
                    objectApiName: 'NPS_Survey_Summary__c',
                    actionName: 'view'
                }
            });
        }
    }

    /**
     * @description Format date for display
     * @param {Date} dateValue - The date to format
     * @returns {String} Formatted date string
     */
    formatDate(dateValue) {
        if (!dateValue) return '—';
        
        try {
            const date = new Date(dateValue);
            return date.toLocaleDateString('en-GB', { 
                day: '2-digit', 
                month: 'short', 
                year: 'numeric' 
            });
        } catch (e) {
            return '—';
        }
    }

    /**
     * @description Format date-time for display
     * @param {DateTime} dateTimeValue - The date-time to format
     * @returns {String} Formatted date-time string
     */
    formatDateTime(dateTimeValue) {
        if (!dateTimeValue) return '—';
        
        try {
            const date = new Date(dateTimeValue);
            return date.toLocaleDateString('en-GB', { 
                day: '2-digit', 
                month: 'short', 
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        } catch (e) {
            return '—';
        }
    }

    /**
     * @description Get sentiment class for styling
     * @param {String} sentiment - The sentiment value
     * @returns {String} CSS class for sentiment
     */
    getSentimentClass(sentiment) {
        if (!sentiment) return 'sentiment-default';
        
        const sentimentLower = sentiment.toLowerCase();
        const sentimentClasses = {
            'positive': 'sentiment-positive',
            'negative': 'sentiment-negative',
            'neutral': 'sentiment-neutral',
            'mixed': 'sentiment-mixed'
        };
        
        return sentimentClasses[sentimentLower] || 'sentiment-default';
    }

    /**
     * @description Component lifecycle - process data when connected
     */
    connectedCallback() {
        console.log('NPS Summary Renderer - Received value:', JSON.stringify(this.value, null, 2));
        
        // Try multiple possible data structures
        let summaryItem = null;
        
        if (this.value) {
            // Check if value has summary property (from SummaryResponse)
            if (this.value.summary) {
                summaryItem = this.value.summary;
            }
            // Check if value is the summary item directly
            else if (this.value.id && this.value.name) {
                summaryItem = this.value;
            }
        }
        
        if (summaryItem) {
            console.log('NPS Summary Renderer - Processing summary:', summaryItem.name);
            this.summaryData = {
                ...summaryItem,
                sentimentClass: this.getSentimentClass(summaryItem.sentimentAnalysis),
                surveyDateFormatted: this.formatDate(summaryItem.surveyDate),
                summaryGenerationDateFormatted: this.formatDateTime(summaryItem.summaryGenerationDate),
                accountNameDisplay: summaryItem.accountName || '—',
                npsSurveyNameDisplay: summaryItem.npsSurveyName || '—',
                npsScoreDisplay: summaryItem.npsScore !== null && summaryItem.npsScore !== undefined 
                    ? summaryItem.npsScore.toString() 
                    : '—',
                followUpRequiredText: summaryItem.followUpRequired ? 'Yes' : 'No'
            };
        } else {
            console.log('NPS Summary Renderer - No summary found in value');
            this.summaryData = null;
        }
    }

    /**
     * @description Check if there is a summary to display
     */
    get hasSummary() {
        return this.summaryData !== null;
    }

    /**
     * @description Get display title
     */
    get displayTitle() {
        return 'Summary Created Successfully';
    }
}

