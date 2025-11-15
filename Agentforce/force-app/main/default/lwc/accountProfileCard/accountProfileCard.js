import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import ACCOUNT_NAME_FIELD from "@salesforce/schema/Account.Name";
import KNOWNAS_FIELD from "@salesforce/schema/Account.Known_As__c";
import CUSTOMERTYPE_FIELD from "@salesforce/schema/Account.Customer_Type_f__c";
import OWNERNAME_FIELD from "@salesforce/schema/Account.Owner.Name";
import OWNERID_FIELD from "@salesforce/schema/Account.OwnerId";
import WEBSITE_FIELD from "@salesforce/schema/Account.Website";
import SERVICESUMMARY_FIELD from "@salesforce/schema/Account.Service_Summary__c";
import LATEST_NPS_CATEGORY_FIELD from "@salesforce/schema/Account.Latest_NPS_Survey_Category__c";
import PRIMARYCONTACT_FIELD from "@salesforce/schema/Account.Key_Contact__r.Name";
import PRIMARYCONTACT_ID_FIELD from "@salesforce/schema/Account.Key_Contact__c";
import CONTRACT_ORDERBOOK_FIELD from "@salesforce/schema/Account.Total_Contract_Orderbook__c";
import CONTRACT_ANNUALVALUE_FIELD from "@salesforce/schema/Account.Current_Spend__c";
import CURRENCY_FIELD from "@salesforce/schema/Account.CurrencyIsoCode";
import OPEN_OPPS_FIELD from "@salesforce/schema/Account.Count_of_Active_Opps__c";

const fields = [
  ACCOUNT_NAME_FIELD,
  KNOWNAS_FIELD,
  CUSTOMERTYPE_FIELD,
  OWNERNAME_FIELD,
  OWNERID_FIELD,
  WEBSITE_FIELD,
  SERVICESUMMARY_FIELD,
  LATEST_NPS_CATEGORY_FIELD,
  PRIMARYCONTACT_FIELD,
  PRIMARYCONTACT_ID_FIELD,
  CONTRACT_ORDERBOOK_FIELD,
  CONTRACT_ANNUALVALUE_FIELD,
  CURRENCY_FIELD,
  OPEN_OPPS_FIELD
];

export default class AccountProfileCard extends LightningElement {
  @api recordId;

  @api backgroundHexCode;
  @api textHexCode;
  @api iconForegroundHexCode;

  @wire(getRecord, { recordId: "$recordId", fields })
  account;

  get isLoaded() {
    return this.account?.data;
  }

  get error() {
    if (this.account?.error) console.error(JSON.stringify(this.account?.error));
    return this.account?.error?.body?.message;
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
    return getFieldValue(this.account.data, ACCOUNT_NAME_FIELD);
  }

  get knownAs() {
    return getFieldValue(this.account.data, KNOWNAS_FIELD);
  }

  get customerType() {
    return getFieldValue(this.account.data, CUSTOMERTYPE_FIELD);
  }

  get ownerName() {
    return getFieldValue(this.account.data, OWNERNAME_FIELD);
  }

  get ownerId() {
    return getFieldValue(this.account.data, OWNERID_FIELD);
  }

  get ownerLink()  {
    return `/${this.ownerId || ''}`;
  }

  get serviceSummary() {
    let serviceSummary = getFieldValue(this.account.data, SERVICESUMMARY_FIELD);
    if (serviceSummary) {
        return serviceSummary.replace(/;/g, ', ');
    } else {
        return null;
    }
  }

  get npsCategory() {
    return getFieldValue(this.account.data, LATEST_NPS_CATEGORY_FIELD);
  }

  get primaryContact() {
    return getFieldValue(this.account.data, PRIMARYCONTACT_FIELD);
  }

  get primaryContactId() {
    return getFieldValue(this.account.data, PRIMARYCONTACT_ID_FIELD);
  }

  get primaryContactLink()  {
    return `/${this.primaryContactId || ''}`;
  }

  get contractOrderbook() {
    return getFieldValue(this.account.data, CONTRACT_ORDERBOOK_FIELD);
  }

  get contractValue() {
    return getFieldValue(this.account.data, CONTRACT_ANNUALVALUE_FIELD);
  }

  get currencyCode() {
    return getFieldValue(this.account.data, CURRENCY_FIELD);
  }

  get openOpps() {
    return getFieldValue(this.account.data, OPEN_OPPS_FIELD);
  }

  get website() {
    return getFieldValue(this.account.data, WEBSITE_FIELD);
  }

}