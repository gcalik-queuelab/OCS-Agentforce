import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import COMPANY_FIELD from "@salesforce/schema/Lead.Company";
import NAME_FIELD from "@salesforce/schema/Lead.Name";
import TITLE_FIELD from "@salesforce/schema/Lead.Title";
import PHONE_FIELD from "@salesforce/schema/Lead.Phone";
import MOBILE_FIELD from "@salesforce/schema/Lead.MobilePhone";
import EMAIL_FIELD from "@salesforce/schema/Lead.Email";
import LASTACTIVITY_FIELD from "@salesforce/schema/Lead.LastActivityDate";
import PRIMARYSOURCE_FIELD from "@salesforce/schema/Lead.Primary_Source__c";
import SECONDARYSOURCE_FIELD from "@salesforce/schema/Lead.Secondary_Source__c";
import ESTIMATEDANNUALVALUE_FIELD from "@salesforce/schema/Lead.Estimated_Annual_Value__c";
import ESTIMATEDCONTRACTTERM_FIELD from "@salesforce/schema/Lead.Contract_Term_String__c";
import ESTIMATEDSTARTDATE_FIELD from "@salesforce/schema/Lead.Estimated_Start_Date__c";
import CURRENCYCODE_FIELD from "@salesforce/schema/Lead.CurrencyIsoCode";
import ENQUIRYSERVICE_FIELD from "@salesforce/schema/Lead.Enquiry_Service__c";

const fields = [
  COMPANY_FIELD,
  NAME_FIELD,
  TITLE_FIELD,
  PHONE_FIELD,
  MOBILE_FIELD,
  EMAIL_FIELD,
  LASTACTIVITY_FIELD,
  PRIMARYSOURCE_FIELD,
  SECONDARYSOURCE_FIELD,
  ESTIMATEDANNUALVALUE_FIELD,
  ESTIMATEDCONTRACTTERM_FIELD,
  ESTIMATEDSTARTDATE_FIELD,
  CURRENCYCODE_FIELD,
  ENQUIRYSERVICE_FIELD
];

export default class leadProfileCard extends LightningElement {
  @api recordId;

  @api backgroundHexCode;
  @api textHexCode;
  @api iconForegroundHexCode;

  @wire(getRecord, { recordId: "$recordId", fields })
  lead;

  get isLoaded() {
    return this.lead?.data;
  }

  get error() {
    if (this.lead?.error) console.error(JSON.stringify(this.lead?.error));
    return this.lead?.error?.body?.message;
  }

  get name() {
    return getFieldValue(this.lead.data, NAME_FIELD);
  }

  get title() {
    return getFieldValue(this.lead.data, TITLE_FIELD);
  }

  get phone() {
    return getFieldValue(this.lead.data, PHONE_FIELD);
  }

  get email() {
    return getFieldValue(this.lead.data, EMAIL_FIELD);
  }

  get mobile() {
    return getFieldValue(this.lead.data, MOBILE_FIELD);
  }

  get lastActivityDate() {
    return getFieldValue(this.lead.data, LASTACTIVITY_FIELD);
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

  get company() {
    return getFieldValue(this.lead.data, COMPANY_FIELD);
  }

  get primarySource() {
    return getFieldValue(this.lead.data, PRIMARYSOURCE_FIELD);
  }

  get secondarySource() {
    return getFieldValue(this.lead.data, SECONDARYSOURCE_FIELD);
  }

  get estimatedAnnualValue() {
    return getFieldValue(this.lead.data, ESTIMATEDANNUALVALUE_FIELD);
  }

  get estimatedContractTerm() {
    return getFieldValue(this.lead.data, ESTIMATEDCONTRACTTERM_FIELD);
  }

  get estimatedStartDate() {
    return getFieldValue(this.lead.data, ESTIMATEDSTARTDATE_FIELD);
  }

  get currencyCode() {
    return getFieldValue(this.lead.data, CURRENCYCODE_FIELD);
  }

  get enquiryService() {
    return getFieldValue(this.lead.data, ENQUIRYSERVICE_FIELD);
  }

}