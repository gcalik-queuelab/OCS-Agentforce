import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_SUMMARY_OBJECT from '@salesforce/schema/Account_Summary__c';
import getRelatedSummariesByAccount from '@salesforce/apex/AccountSummaryRelatedListController.getRelatedSummariesByAccount';
import { refreshApex } from '@salesforce/apex';

export default class AccountSummaryRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api title = 'Account Summaries';
    @api maxRecords = 100;

    summaries = [];
    allSummaries = [];
    isLoading = false;
    error;
    wiredSummariesResult;
    sortBy = 'summaryGenerationDate';
    sortDirection = 'desc';
    objectInfo;

    @wire(getObjectInfo, { objectApiName: ACCOUNT_SUMMARY_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getRelatedSummariesByAccount, { accountId: '$recordId', maxRecords: '$maxRecords' })
    wiredSummariesByAccount(result) {
        this.wiredSummariesResult = result;
        this.isLoading = result.data ? false : true;

        if (result.data) {
            this.allSummaries = result.data.map(summary => {
                const formattedDate = summary.summaryGenerationDate ?
                    new Date(summary.summaryGenerationDate).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }) :
                    '—';
                return {
                    ...summary,
                    createdByAgentforceText: summary.createdByAgentforce ? 'Auto' : 'Manual',
                    summaryGenerationDateFormatted: formattedDate,
                    statusClass: this.getStatusClass(summary.generationStatus),
                    priorityClass: this.getPriorityClass(summary.priorityLevel),
                    sentimentClass: this.getSentimentClass(summary.sentimentAnalysis)
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

    getStatusClass(status) {
        if (status === 'Completed') return 'slds-text-color_success';
        if (status === 'Failed') return 'slds-text-color_error';
        if (status === 'Pending') return 'slds-text-color_default';
        return '';
    }

    getPriorityClass(priority) {
        if (priority === 'High') return 'slds-text-color_error';
        if (priority === 'Medium') return 'slds-text-color_default';
        if (priority === 'Low') return 'slds-text-color_weak';
        return '';
    }

    getSentimentClass(sentiment) {
        if (sentiment === 'Positive' || sentiment === 'Improving') return 'slds-text-color_success';
        if (sentiment === 'Negative' || sentiment === 'Declining') return 'slds-text-color_error';
        if (sentiment === 'Neutral' || sentiment === 'Mixed') return 'slds-text-color_default';
        return '';
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
