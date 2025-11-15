import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import NAME_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Name";
import CONTRACT_NAME_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Contract_Name__c";
import CONTRACT_ID_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__c";
import ACCOUNT_NAME_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Account__r.Name";
import ACCOUNT_ID_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Account__c";
import STATUS_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Status__c";
import STARTDATE_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Contract_Start_Date__c";
import ENDDATE_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Contract_End_Date__c";
import LAST_RENEWED_DATE_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Contract_Last_Renewed__c";
import CONTRACT_TERM_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Contract_Term_String__c";
import OWNERNAME_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Owner_Full_Name__c";
import OWNER_ID_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.OwnerId";
import SERVICESUMMARY_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Service_Summary__c";
import PRIMARYCONTACT_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Key_Contact__r.Name";
import PRIMARYCONTACT_ID_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Key_Contact__c";
import CONTRACT_ORDERBOOK_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Contract_Orderbook__c";
import ACTUAL_ANNUALVALUE_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.Actual_Annual_Revenue__c";
import CURRENCY_FIELD from "@salesforce/schema/Contract_Terms__c.Contract__r.CurrencyIsoCode";

const fields = [
  NAME_FIELD,
  CONTRACT_NAME_FIELD,
  CONTRACT_ID_FIELD,
  ACCOUNT_NAME_FIELD,
  ACCOUNT_ID_FIELD,
  STATUS_FIELD,
  STARTDATE_FIELD,
  ENDDATE_FIELD,
  LAST_RENEWED_DATE_FIELD,
  CONTRACT_TERM_FIELD,
  OWNERNAME_FIELD,
  OWNER_ID_FIELD,
  SERVICESUMMARY_FIELD,
  PRIMARYCONTACT_FIELD,
  PRIMARYCONTACT_ID_FIELD,
  CONTRACT_ORDERBOOK_FIELD,
  ACTUAL_ANNUALVALUE_FIELD,
  CURRENCY_FIELD
];

export default class ContractTermProfileCard extends LightningElement {
  @api recordId;

  @api backgroundHexCode;
  @api textHexCode;
  @api iconForegroundHexCode;

  @wire(getRecord, { recordId: "$recordId", fields })
  contractterm;

  get isLoaded() {
    return this.contractterm?.data;
  }

  get error() {
    if (this.contractterm?.error) console.error(JSON.stringify(this.contract?.error));
    return this.contractterm?.error?.body?.message;
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

  get name() {
    return getFieldValue(this.contractterm.data, NAME_FIELD);
  }

  get contractname() {
    return getFieldValue(this.contractterm.data, CONTRACT_NAME_FIELD);
  }

  get contractId() {
    return getFieldValue(this.contractterm.data, CONTRACT_ID_FIELD);
  }

  get contractLink()  {
    return `/${this.contractId || ''}`;
  }

  get accountName() {
    return getFieldValue(this.contractterm.data, ACCOUNT_NAME_FIELD);
  }

  get accountId() {
    return getFieldValue(this.contractterm.data, ACCOUNT_ID_FIELD);
  }

  get accountLink()  {
    return `/${this.accountId || ''}`;
  }

  get status() {
    return getFieldValue(this.contractterm.data, STATUS_FIELD);
  }

  get startDate() {
    return getFieldValue(this.contractterm.data, STARTDATE_FIELD);
  }

  get endDate() {
    return getFieldValue(this.contractterm.data, ENDDATE_FIELD);
  }

  get lastRenewedDate() {
    return getFieldValue(this.contractterm.data, LAST_RENEWED_DATE_FIELD);
  }

  get contractTerm() {
    return getFieldValue(this.contractterm.data, CONTRACT_TERM_FIELD);
  }

  get ownerName() {
    return getFieldValue(this.contractterm.data, OWNERNAME_FIELD);
  }

  get ownerId() {
    return getFieldValue(this.contractterm.data, OWNER_ID_FIELD);
  }

  get ownerLink()  {
    return `/${this.ownerId || ''}`;
  }

  get serviceSummary() {
    let serviceSummary = getFieldValue(this.contractterm.data, SERVICESUMMARY_FIELD);
    if (serviceSummary) {
        return serviceSummary.replace(/;/g, ', ');
    } else {
        return null;
    }
  }

  get primaryContact() {
    return getFieldValue(this.contractterm.data, PRIMARYCONTACT_FIELD);
  }

  get primaryContactId() {
    return getFieldValue(this.contractterm.data, PRIMARYCONTACT_ID_FIELD);
  }

  get primaryContactLink()  {
    return `/${this.primaryContactId || ''}`;
  }

  get contractOrderbook() {
    return getFieldValue(this.contractterm.data, CONTRACT_ORDERBOOK_FIELD);
  }

  get actualAnnualValue() {
    return getFieldValue(this.contractterm.data, ACTUAL_ANNUALVALUE_FIELD);
  }

  get currencyCode() {
    return getFieldValue(this.contractterm.data, CURRENCY_FIELD);
  }

}