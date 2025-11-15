import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import ACCOUNT_NAME_FIELD from "@salesforce/schema/Contact.Account.Name";
import ACCOUNT_ID_FIELD from "@salesforce/schema/Contact.AccountId";
import ACCOUNT_KNOWNAS_FIELD from "@salesforce/schema/Contact.Account.Known_As__c";
import ACCOUNT_CUSTOMERTYPE_FIELD from "@salesforce/schema/Contact.Account.Customer_Type_f__c";
import NAME_FIELD from "@salesforce/schema/Contact.Name";
import OPEN_OPPS_FIELD from "@salesforce/schema/Contact.No_of_Open_Opportunities__c";
import ACTIVE_CONTRACTS_FIELD from "@salesforce/schema/Contact.No_of_Active_Contracts__c";
import TITLE_FIELD from "@salesforce/schema/Contact.Title";
import PHONE_FIELD from "@salesforce/schema/Contact.Phone";
import MOBILE_FIELD from "@salesforce/schema/Contact.MobilePhone";
import EMAIL_FIELD from "@salesforce/schema/Contact.Email";
import LASTACTIVITY_FIELD from "@salesforce/schema/Contact.LastActivityDate";
import PERCEPTION_FIELD from "@salesforce/schema/Contact.Latest_Perception__c";
import OWNER_NAME_FIELD from "@salesforce/schema/Contact.Owner.Name";
import OWNER_ID_FIELD from "@salesforce/schema/Contact.OwnerId";

const fields = [
  ACCOUNT_NAME_FIELD,
  ACCOUNT_ID_FIELD,
  ACCOUNT_KNOWNAS_FIELD,
  ACCOUNT_CUSTOMERTYPE_FIELD,
  NAME_FIELD,
  TITLE_FIELD,
  PHONE_FIELD,
  MOBILE_FIELD,
  EMAIL_FIELD,
  LASTACTIVITY_FIELD,
  PERCEPTION_FIELD,
  OPEN_OPPS_FIELD,
  OWNER_NAME_FIELD,
  OWNER_ID_FIELD,
  ACTIVE_CONTRACTS_FIELD
];

export default class ContactProfileCard extends LightningElement {
  @api recordId;

  @api backgroundHexCode;
  @api textHexCode;
  @api iconForegroundHexCode;

  @wire(getRecord, { recordId: "$recordId", fields })
  contact;

  get isLoaded() {
    return this.contact?.data;
  }

  get error() {
    if (this.contact?.error) console.error(JSON.stringify(this.contact?.error));
    return this.contact?.error?.body?.message;
  }

  get name() {
    return getFieldValue(this.contact.data, NAME_FIELD);
  }

  get title() {
    return getFieldValue(this.contact.data, TITLE_FIELD);
  }

  get phone() {
    return getFieldValue(this.contact.data, PHONE_FIELD);
  }

  get email() {
    return getFieldValue(this.contact.data, EMAIL_FIELD);
  }

  get latestPerception() {
    return getFieldValue(this.contact.data, PERCEPTION_FIELD);
  }

  get mobile() {
    return getFieldValue(this.contact.data, MOBILE_FIELD);
  }

  get lastActivityDate() {
    return getFieldValue(this.contact.data, LASTACTIVITY_FIELD);
  }

  get openOpps() {
    return getFieldValue(this.contact.data, OPEN_OPPS_FIELD);
  }

  get activeContracts() {
    return getFieldValue(this.contact.data, ACTIVE_CONTRACTS_FIELD);
  }

  get phonemobileconcat()  {
    return `${this.phone || ''}${this.mobile || ''}`;
  }

  get emaillink()  {
    return `mailto:${this.email || ''}`;
  }

  get phonelink()  {
    return `tel:${this.phone || ''}`;
  }

  get mobilelink()  {
    return `tel:${this.mobile || ''}`;
  }

  get photoURL() {
    return photoURL ? photoURL : "https://res.cloudinary.com/btahub/image/upload/v1708357811/ntbg5p1mwixury672dxy.png";
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
    return getFieldValue(this.contact.data, ACCOUNT_NAME_FIELD);
  }

  get accountId() {
    return getFieldValue(this.contact.data, ACCOUNT_ID_FIELD);
  }

  get accountLink()  {
    return `/${this.accountId || ''}`;
  }

  get accountKnownAs() {
    return getFieldValue(this.contact.data, ACCOUNT_KNOWNAS_FIELD);
  }

  get account() {
    return this.accountKnownAs || this.accountName;
  }

  get ownerName() {
    return getFieldValue(this.contact.data, OWNER_NAME_FIELD);
  }

  get ownerId() {
    return getFieldValue(this.contact.data, OWNER_ID_FIELD);
  }

  get ownerLink()  {
    return `/${this.ownerId || ''}`;
  }

  get accountCustomerType() {
    return getFieldValue(this.contact.data, ACCOUNT_CUSTOMERTYPE_FIELD);
  }

}