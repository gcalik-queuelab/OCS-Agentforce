import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import ACCOUNT_NAME_FIELD from "@salesforce/schema/Opportunity.Account.Name";
import ACCOUNT_ID_FIELD from "@salesforce/schema/Opportunity.AccountId";
import RECORD_TYPE_FIELD from "@salesforce/schema/Opportunity.RecordType.Name";
import TYPE_FIELD from "@salesforce/schema/Opportunity.Type";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_Stage__c";
import STARTDATE_FIELD from "@salesforce/schema/Opportunity.Contract_Start_Date__c";
import ENDDATE_FIELD from "@salesforce/schema/Opportunity.Contract_End_Date__c";
import CONTRACT_TERM_FIELD from "@salesforce/schema/Opportunity.Contract_Term_String__c";
import OWNERNAME_FIELD from "@salesforce/schema/Opportunity.Owner_Full_Name__c";
import OWNER_ID_FIELD from "@salesforce/schema/Opportunity.OwnerId";
import SERVICESUMMARY_FIELD from "@salesforce/schema/Opportunity.Service_Summary__c";
import KEYCONTACT_NAME_FIELD from "@salesforce/schema/Opportunity.Primary_Contact__r.Name";
import KEYCONTACT_ID_FIELD from "@salesforce/schema/Opportunity.Primary_Contact__c";
import ANNUAL_REVENUE_FIELD from "@salesforce/schema/Opportunity.Amount";
import CONTRACTNAME_FIELD from "@salesforce/schema/Opportunity.Contract_Number__c";
import CONTRACT_ID_FIELD from "@salesforce/schema/Opportunity.ContractCaseSafeID__c";
import AWARDDATE_FIELD from "@salesforce/schema/Opportunity.CloseDate";
import CURRENCY_FIELD from "@salesforce/schema/Opportunity.CurrencyIsoCode";

const fields = [
  ACCOUNT_NAME_FIELD,
  ACCOUNT_ID_FIELD,
  RECORD_TYPE_FIELD,
  TYPE_FIELD,
  SUBSTAGE_FIELD,
  ANNUAL_REVENUE_FIELD,
  CONTRACTNAME_FIELD,
  CONTRACT_ID_FIELD,
  KEYCONTACT_NAME_FIELD,
  KEYCONTACT_ID_FIELD,
  STARTDATE_FIELD,
  ENDDATE_FIELD,
  CONTRACT_TERM_FIELD,
  OWNERNAME_FIELD,
  OWNER_ID_FIELD,
  SERVICESUMMARY_FIELD,
  AWARDDATE_FIELD,
  CURRENCY_FIELD
];

export default class OpportunityProfileCard extends LightningElement {
  @api recordId;

  @api backgroundHexCode;
  @api textHexCode;
  @api iconForegroundHexCode;

  @wire(getRecord, { recordId: "$recordId", fields })
  opportunity;

  get isLoaded() {
    return this.opportunity?.data;
  }

  get error() {
    if (this.opportunity?.error) console.error(JSON.stringify(this.opportunity?.error));
    return this.opportunity?.error?.body?.message;
  }

  get backgroundColorStyle() {
    return `--background-color: ${this.backgroundHexCode || '#293771'}`;
  }

  get textColorStyle() {
    return `--text-color: ${this.textHexCode || '#FFFFFF'}`;
  }

  get iconForegroundColorStyle() {
    return `--icon-foreground-color: ${this.iconForegroundHexCode || '#FFFFFF'}`;
  }

  get accountName() {
    return getFieldValue(this.opportunity.data, ACCOUNT_NAME_FIELD);
  }

  get accountId() {
    return getFieldValue(this.opportunity.data, ACCOUNT_ID_FIELD);
  }

  get accountLink()  {
    return `/${this.accountId || ''}`;
  }

  get subStage() {
    return getFieldValue(this.opportunity.data, SUBSTAGE_FIELD);
  }

  get type() {
    return getFieldValue(this.opportunity.data, TYPE_FIELD);
  }

  get startDate() {
    return getFieldValue(this.opportunity.data, STARTDATE_FIELD);
  }

  get endDate() {
    return getFieldValue(this.opportunity.data, ENDDATE_FIELD);
  }

  get recordType() {
    return getFieldValue(this.opportunity.data, RECORD_TYPE_FIELD);
  }

  get contractTerm() {
    return getFieldValue(this.opportunity.data, CONTRACT_TERM_FIELD);
  }

  get contractName() {
    return getFieldValue(this.opportunity.data, CONTRACTNAME_FIELD);
  }

  get contractId() {
    return getFieldValue(this.opportunity.data, CONTRACT_ID_FIELD);
  }

  get contractLink()  {
    return `/${this.contractId || ''}`;
  }

  get ownerName() {
    return getFieldValue(this.opportunity.data, OWNERNAME_FIELD);
  }

  get ownerId() {
    return getFieldValue(this.opportunity.data, OWNER_ID_FIELD);
  }

  get ownerLink()  {
    return `/${this.ownerId || ''}`;
  }

  get serviceSummary() {
    let serviceSummary = getFieldValue(this.opportunity.data, SERVICESUMMARY_FIELD);
    if (serviceSummary) {
        return serviceSummary.replace(/;/g, ', ');
    } else {
        return null;
    }
  }

  get keyContact() {
    return getFieldValue(this.opportunity.data, KEYCONTACT_NAME_FIELD);
  }

  get keyContactId() {
    return getFieldValue(this.opportunity.data, KEYCONTACT_ID_FIELD);
  }

  get keyContactLink()  {
    return `/${this.keyContactId || ''}`;
  }

  get annualRevenue() {
    return getFieldValue(this.opportunity.data, ANNUAL_REVENUE_FIELD);
  }

  get awardDate() {
    return getFieldValue(this.opportunity.data, AWARDDATE_FIELD);
  }

  get currencyCode() {
    return getFieldValue(this.opportunity.data, CURRENCY_FIELD);
  }

}