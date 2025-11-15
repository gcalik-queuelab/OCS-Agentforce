import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import NAME_FIELD from "@salesforce/schema/Contract__c.Name";
import ACCOUNT_NAME_FIELD from "@salesforce/schema/Contract__c.Account__r.Name";
import ACCOUNT_ID_FIELD from "@salesforce/schema/Contract__c.Account__c";
import STATUS_FIELD from "@salesforce/schema/Contract__c.Status__c";
import RISK_STATUS_FIELD from "@salesforce/schema/Contract__c.Risk_Status__c";
import STARTDATE_FIELD from "@salesforce/schema/Contract__c.Contract_Start_Date__c";
import ENDDATE_FIELD from "@salesforce/schema/Contract__c.Contract_End_Date__c";
import LAST_RENEWED_DATE_FIELD from "@salesforce/schema/Contract__c.Contract_Last_Renewed__c";
import CONTRACT_TERM_FIELD from "@salesforce/schema/Contract__c.Contract_Term_String__c";
import OWNERNAME_FIELD from "@salesforce/schema/Contract__c.Owner_Full_Name__c";
import OWNER_ID_FIELD from "@salesforce/schema/Contract__c.OwnerId";
import SERVICESUMMARY_FIELD from "@salesforce/schema/Contract__c.Service_Summary__c";
import PRIMARYCONTACT_FIELD from "@salesforce/schema/Contract__c.Key_Contact__r.Name";
import PRIMARYCONTACT_ID_FIELD from "@salesforce/schema/Contract__c.Key_Contact__c";
import CONTRACT_ORDERBOOK_FIELD from "@salesforce/schema/Contract__c.Contract_Orderbook__c";
import ACTUAL_ANNUALVALUE_FIELD from "@salesforce/schema/Contract__c.Actual_Annual_Revenue__c";
import RENEWAL_OPP_TYPE_FIELD from "@salesforce/schema/Contract__c.Renewal_Opportunity_Type__c";
import RENEWAL_OPP_VALUE_FIELD from "@salesforce/schema/Contract__c.Renewal_Opportunity_Annual_Revenue__c";
import CURRENCY_FIELD from "@salesforce/schema/Contract__c.CurrencyIsoCode";

const fields = [
  NAME_FIELD,
  ACCOUNT_NAME_FIELD,
  ACCOUNT_ID_FIELD,
  STATUS_FIELD,
  RISK_STATUS_FIELD,
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
  RENEWAL_OPP_TYPE_FIELD,
  RENEWAL_OPP_VALUE_FIELD,
  CURRENCY_FIELD
];

export default class ContractProfileCard extends LightningElement {
  @api recordId;

  @api backgroundHexCode;
  @api textHexCode;
  @api iconForegroundHexCode;

  @wire(getRecord, { recordId: "$recordId", fields })
  contract;

  get isLoaded() {
    return this.contract?.data;
  }

  get error() {
    if (this.contract?.error) console.error(JSON.stringify(this.contract?.error));
    return this.contract?.error?.body?.message;
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
    return getFieldValue(this.contract.data, NAME_FIELD);
  }

  get accountName() {
    return getFieldValue(this.contract.data, ACCOUNT_NAME_FIELD);
  }

  get accountId() {
    return getFieldValue(this.contract.data, ACCOUNT_ID_FIELD);
  }

  get accountLink()  {
    return `/${this.accountId || ''}`;
  }

  get status() {
    return getFieldValue(this.contract.data, STATUS_FIELD);
  }

  get startDate() {
    return getFieldValue(this.contract.data, STARTDATE_FIELD);
  }

  get endDate() {
    return getFieldValue(this.contract.data, ENDDATE_FIELD);
  }

  get lastRenewedDate() {
    return getFieldValue(this.contract.data, LAST_RENEWED_DATE_FIELD);
  }

  get contractTerm() {
    return getFieldValue(this.contract.data, CONTRACT_TERM_FIELD);
  }

  get ownerName() {
    return getFieldValue(this.contract.data, OWNERNAME_FIELD);
  }

  get ownerId() {
    return getFieldValue(this.contract.data, OWNER_ID_FIELD);
  }

  get ownerLink()  {
    return `/${this.ownerId || ''}`;
  }

  get serviceSummary() {
    let serviceSummary = getFieldValue(this.contract.data, SERVICESUMMARY_FIELD);
    if (serviceSummary) {
        return serviceSummary.replace(/;/g, ', ');
    } else {
        return null;
    }
  }

  get primaryContact() {
    return getFieldValue(this.contract.data, PRIMARYCONTACT_FIELD);
  }

  get primaryContactId() {
    return getFieldValue(this.contract.data, PRIMARYCONTACT_ID_FIELD);
  }

  get primaryContactLink()  {
    return `/${this.primaryContactId || ''}`;
  }

  get contractOrderbook() {
    return getFieldValue(this.contract.data, CONTRACT_ORDERBOOK_FIELD);
  }

  get actualAnnualValue() {
    return getFieldValue(this.contract.data, ACTUAL_ANNUALVALUE_FIELD);
  }

  get renewalOppType() {
    return getFieldValue(this.contract.data, RENEWAL_OPP_TYPE_FIELD);
  }

  get renewalOppValue() {
    return getFieldValue(this.contract.data, RENEWAL_OPP_VALUE_FIELD);
  }

  get currencyCode() {
    return getFieldValue(this.contract.data, CURRENCY_FIELD);
  }

}