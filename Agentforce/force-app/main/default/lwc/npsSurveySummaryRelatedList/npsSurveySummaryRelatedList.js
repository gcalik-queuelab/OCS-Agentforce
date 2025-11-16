import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import NPS_SURVEY_SUMMARY_OBJECT from '@salesforce/schema/NPS_Survey_Summary__c';
import getRelatedSummariesByNPS from '@salesforce/apex/NPSSurveySummaryRelatedListController.getRelatedSummariesByNPS';
import getRelatedSummariesByAccount from '@salesforce/apex/NPSSurveySummaryRelatedListController.getRelatedSummariesByAccount';
import { refreshApex } from '@salesforce/apex';

export default class NpsSurveySummaryRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api title = 'NPS Survey Summaries';
    @api maxRecords = 100;
    @api contextObject; // 'NPS__c' or 'Account'

    summaries = [];
    allSummaries = [];
    isLoading = false;
    error;
    wiredSummariesResult;
    sortBy = 'summaryGenerationDate';
    sortDirection = 'desc';
    objectInfo;

    @wire(getObjectInfo, { objectApiName: NPS_SURVEY_SUMMARY_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            this.error = error;
        }
    }

    connectedCallback() {
        // Determine context object from the record page
        // This will be set via the flexipage configuration
        if (!this.contextObject && this.recordId) {
            // Try to infer from recordId prefix
            // Account IDs typically start with '001', NPS__c would have a different prefix
            // For now, we'll use the property set in flexipage, but provide fallback logic
            // The component should be configured with contextObject property in the flexipage
        }
    }

    @wire(getRelatedSummariesByNPS, { npsSurveyId: '$recordId', maxRecords: '$maxRecords' })
    wiredSummariesByNPS(result) {
        // Only process if context is NPS__c
        if (this.contextObject === 'NPS__c') {
            this.handleWiredResult(result);
        } else if (!this.contextObject && result.data && result.data.length > 0) {
            // Auto-detect: if we get data from NPS query, assume context is NPS__c
            this.contextObject = 'NPS__c';
            this.handleWiredResult(result);
        }
    }

    @wire(getRelatedSummariesByAccount, { accountId: '$recordId', maxRecords: '$maxRecords' })
    wiredSummariesByAccount(result) {
        // Only process if context is Account
        if (this.contextObject === 'Account') {
            this.handleWiredResult(result);
        } else if (!this.contextObject && result.data && result.data.length > 0 && !this.summaries.length) {
            // Auto-detect: if we get data from Account query and no summaries yet, assume context is Account
            this.contextObject = 'Account';
            this.handleWiredResult(result);
        }
    }

    handleWiredResult(result) {
        this.wiredSummariesResult = result;
        this.isLoading = result.data ? false : true;

        if (result.data) {
            this.allSummaries = result.data.map(summary => {
                const formattedDate = summary.surveyDate ? 
                    new Date(summary.surveyDate).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }) : 
                    '—';
                return {
                    ...summary,
                    followUpRequiredText: summary.followUpRequired ? 'Yes' : 'No',
                    relatedFieldValue: this.contextObject === 'Account' ? summary.npsSurveyName : summary.accountName,
                    surveyDateFormatted: formattedDate
                };
            });
            this.sortData(this.sortBy, this.sortDirection);
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.summaries = [];
            this.allSummaries = [];
        }
    }

    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredSummariesResult);
    }

    handleSummaryClick(event) {
        event.preventDefault();
        const summaryId = event.target.dataset.id || event.currentTarget.dataset.id;
        if (summaryId) {
            this.navigateToRecord(summaryId);
        }
    }

    navigateToRecord(recordId, mode = 'view') {
        const pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: mode
            }
        };

        this[NavigationMixin.Navigate](pageReference);
    }

    get hasSummaries() {
        return this.summaries && this.summaries.length > 0;
    }

    get summaryCount() {
        return this.summaries ? this.summaries.length : 0;
    }

    get relatedFieldLabel() {
        return this.contextObject === 'Account' ? 'NPS Survey' : 'Account';
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortBy = fieldName;
        this.sortDirection = sortDirection;
        this.sortData(fieldName, sortDirection);
    }

    sortData(fieldName, direction) {
        let parseData = JSON.parse(JSON.stringify(this.allSummaries));

        let keyValue = (a) => {
            return a[fieldName];
        };

        let isReverse = direction === 'asc' ? 1 : -1;

        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';

            return isReverse * ((x > y) - (y > x));
        });

        this.summaries = parseData;
    }
}

