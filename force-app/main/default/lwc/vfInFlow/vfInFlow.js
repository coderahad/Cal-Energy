import { LightningElement, api } from 'lwc';

export default class VfInFlow extends LightningElement {
  // Inputs from Flow
  @api pageName = 'QuotePdf';      // e.g., "MyVFPage"
  @api queryString;   // e.g., "id={!$Record.Id}&mode=preview"
  @api height = '700';// iframe height in px

  @api recordId = new URL(window.location.href).searchParams.get("recordId");


  get computedStyle() {
    return `height:${this.height}px;`;
  }

  // Build VF URL on the fly for the current org (works in sandboxes & prod)
  get vfUrl() {
    // Current host could be *.lightning.force.com or *.my.salesforce.com
    const { protocol, hostname } = window.location;
    // Map to the matching Visualforce domain
    // - prod:  yourdomain.lightning.force.com -> yourdomain.visualforce.com
    // - sandbox: yourdomain--sbx.lightning.force.com -> yourdomain--sbx.visualforce.com
    // - my domain classic host: yourdomain.my.salesforce.com -> yourdomain--c.visualforce.com (Salesforce auto-handles)
    let vfHost = hostname
      .replace('.lightning.force.com', '.my.salesforce.com')
      // .replace('.my.salesforce.com', '.vf.force.com');

    const base = `${protocol}//${vfHost}/apex/${this.pageName}?id=${this.recordId}`;
    console.log(base)
    return base;
  }
}