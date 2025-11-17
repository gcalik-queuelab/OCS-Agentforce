/**
 * @description Professional NPS survey list renderer for Agentforce
 * Following official caseListRenderer pattern from Salesforce documentation
 */
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NpsSurveyListRenderer extends NavigationMixin(LightningElement) {
    
    surveyData = [];

    @api
    get value() {
        return this._value;
    }
    
    /**
     * @param  {NPSSurveyList} value - The NPS survey list data from Apex
     */
    set value(value) {
        this._value = value;
    }

    /**
     * @description Format status for display
     * @param {String} status - The survey status
     * @returns {String} CSS class for status
     */
    getStatusClass(status) {
        if (!status) return 'status-default';
        
        const statusLower = status.toLowerCase();
        const statusClasses = {
            'closed': 'status-closed',
            'completed': 'status-completed',
            'open': 'status-open',
            'scheduled': 'status-scheduled',
            'overdue': 'status-overdue',
            'cancelled': 'status-cancelled'
        };
        
        return statusClasses[statusLower] || 'status-default';
    }

    /**
     * @description Format NPS score for display
     * @param {Number} score - The NPS score
     * @returns {String} CSS class for score
     */
    getScoreClass(score) {
        if (score === null || score === undefined) return 'score-neutral';
        
        if (score >= 50) return 'score-promoter';
        if (score >= 0) return 'score-passive';
        return 'score-detractor';
    }

    /**
     * @description Handle survey click to navigate to survey record
     * @param {Event} event - Click event
     */
    handleSurveyClick(event) {
        const surveyId = event.currentTarget.dataset.surveyId;
        
        if (surveyId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: surveyId,
                    objectApiName: 'NPS__c',
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
     * @description Component lifecycle - process data when connected
     */
    connectedCallback() {
        // Debug: Log the value to see what we're receiving
        console.log('NPS Survey Renderer - Received value:', JSON.stringify(this.value, null, 2));
        
        // Try multiple possible data structures
        let surveysArray = null;
        
        if (this.value) {
            // Check if value has surveys property (direct NPSSurveyList - matches Lightning Type)
            if (this.value.surveys && Array.isArray(this.value.surveys)) {
                surveysArray = this.value.surveys;
            }
            // Check if value is the output schema wrapper with availableSurveys (from SurveyResponse)
            else if (this.value.availableSurveys) {
                if (this.value.availableSurveys.surveys && Array.isArray(this.value.availableSurveys.surveys)) {
                    surveysArray = this.value.availableSurveys.surveys;
                } else if (Array.isArray(this.value.availableSurveys)) {
                    surveysArray = this.value.availableSurveys;
                }
            }
            // Check if value itself is an array
            else if (Array.isArray(this.value)) {
                surveysArray = this.value;
            }
            // Check if value has surveyItems (alternative property name)
            else if (this.value.surveyItems && Array.isArray(this.value.surveyItems)) {
                surveysArray = this.value.surveyItems;
            }
        }
        
        if (surveysArray && surveysArray.length > 0) {
            console.log('NPS Survey Renderer - Processing surveys:', surveysArray.length);
            this.surveyData = surveysArray.map((surveyItem) => {
                return {
                    ...surveyItem,
                    statusClass: this.getStatusClass(surveyItem.status),
                    scoreClass: this.getScoreClass(surveyItem.totalNPSScore),
                    surveyDateFormatted: this.formatDate(surveyItem.surveyDate),
                    accountNameDisplay: surveyItem.accountName || '—',
                    contactNameDisplay: surveyItem.contactName || '—',
                    ownerNameDisplay: surveyItem.ownerName || '—',
                    npsScoreDisplay: surveyItem.totalNPSScore !== null && surveyItem.totalNPSScore !== undefined 
                        ? surveyItem.totalNPSScore.toString() 
                        : '—',
                    averageScoreDisplay: surveyItem.averageScore !== null && surveyItem.averageScore !== undefined 
                        ? surveyItem.averageScore.toFixed(1) 
                        : '—'
                };
            });
        } else {
            console.log('NPS Survey Renderer - No surveys found in value');
            this.surveyData = [];
        }
    }

    /**
     * @description Get total count for display
     */
    get totalCount() {
        return this.surveyData ? this.surveyData.length : 0;
    }

    /**
     * @description Check if there are surveys to display
     */
    get hasSurveys() {
        return this.surveyData && this.surveyData.length > 0;
    }

    /**
     * @description Get display title
     */
    get displayTitle() {
        const count = this.totalCount;
        if (count === 0) return 'No NPS Surveys';
        if (count === 1) return '1 NPS Survey';
        return `${count} NPS Surveys`;
    }
}
