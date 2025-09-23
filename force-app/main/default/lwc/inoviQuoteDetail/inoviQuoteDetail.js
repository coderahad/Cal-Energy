import { LightningElement, api, track } from 'lwc';
import getQuoteDetails from '@salesforce/apex/InoviQuoteController.getQuoteDetails';
import saveSelectedQuoteLines from '@salesforce/apex/InoviQuoteController.saveSelectedQuoteLines';
import updateQuoteStatus from '@salesforce/apex/InoviQuoteController.updateQuoteStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class InoviQuoteDetail extends LightningElement {
    @api recordId;
    @track quote = {};
    @track quoteLines = [];
    @track selectedRows = [];
    @track quoteStatus = null;
    @track poNumber = '';
    @track isModalOpen = false;

    isTemplate1 = false;
    isTemplate2 = false;

    columns = [
        { label: 'Product', fieldName: 'ProductName', type: 'text' },
        { label: 'Quantity', fieldName: 'Quantity', type: 'number' },
        { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency' },
        { label: 'Total Price', fieldName: 'TotalPrice', type: 'currency' }
    ];

    connectedCallback() {
        console.log('recordId:'+ this.recordId);
        this.loadData();
    }

    get isAccepted() {
        return this.quoteStatus === 'Accepted';
    }

    get isDenied() {
        return this.quoteStatus === 'Denied';
    }

    get showAcceptAndDeniedButton(){
        return this.isAccepted == false && this.isDenied == false;
    }

    loadData() {
        getQuoteDetails({ quoteId: this.recordId })
        .then(result => {
            this.quote = result.quote;

            this.isTemplate1 = this.quote.Quote_Template__c == 'Quote Template 1';
            this.isTemplate2 = this.quote.Quote_Template__c == 'Quote Template 2';

            this.quoteStatus = this.quote.Status;
            this.poNumber = this.quote.PO_Number__c || '';
            
            this.quoteLines = result.quoteLines.map(item => ({
                ...item,
                ProductName: item.Product2?.Name || 'N/A'
            }));

            this.selectedRows = result.quoteLines
            .filter(item => item.Selected__c === true)
            .map(item => item.Id);
            
            console.log('selectedRows:'+ JSON.stringify(this.selectedRows));
        })
        .catch(error => {
            console.error('Error loading quote details:', error);
            this.showToast('Error', 'Error loading quote details: ' + this.reduceErrors(error), 'error');
        });
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows.map(row => row.Id);
    }
    
    // New method to open modal when Accept is clicked
    handleAcceptClick() {
        this.isModalOpen = true;
    }
    
    // Close the modal
    closeModal() {
        this.isModalOpen = false;
    }
    
    // Handle work order number input change
    handlePONumberChange(event) {
        this.poNumber = event.target.value;
    }
    
    // Submit work order and accept quote
    submitWorkOrder() {
        // if (!this.poNumber) {
        //     this.showToast('Error', 'Please enter a Work Order Number', 'error');
        //     return;
        // }
        
        // Call apex method to update quote with work order number and status
        updateQuoteStatus({ 
            quoteId: this.recordId,
            status: 'Accepted',
            poNumber: this.poNumber,
        })
        .then((result) => {
            if(result.includes('Failed')){
                this.isModalOpen = false;
                this.showToast('Error', result, 'error');
            }
            else if(result.includes('success')){
                this.quoteStatus = 'Accepted';
                this.isModalOpen = false;
                this.showToast('Success', 'Quote accepted with PO Number: ' + this.poNumber, 'success');
            }

            console.log('result:', JSON.stringify(result));

        })
        .catch(error => {
            console.error('Error updating quote:', error);
            this.showToast('Error', 'Error updating quote: ' + this.reduceErrors(error), 'error');
        });
    }

    // Original decline handler - no changes needed
    handleDecline() {
        this.updateStatus('Denied');
    }

    updateStatus(newStatus) {
        updateQuoteStatus({ quoteId: this.recordId, status: newStatus, poNumber: '' })
            .then(() => {
                console.log(`Quote status updated to ${newStatus}`);
                this.quoteStatus = newStatus;
                this.showToast('Success', `Quote ${newStatus.toLowerCase()} successfully`, 'success');
            })
            .catch(error => {
                console.error('Error updating quote status:', error);
                this.showToast('Error', 'Error updating quote status: ' + this.reduceErrors(error), 'error');
            });
    }

    handleSave() {
        console.log('selectedrows:'+ JSON.stringify(this.selectedRows));
        saveSelectedQuoteLines({ quoteLineIds: this.selectedRows })
        .then(result => {
            console.log('result:'+ JSON.stringify(result));
            this.showToast('Success', 'Selected quote lines saved successfully', 'success');
        })
        .catch(error => {
            console.log('error:'+ JSON.stringify(error));
            this.showToast('Error', 'Error saving selected quote lines: ' + this.reduceErrors(error), 'error');
        });
    }
    
    // Helper method to show toast notifications
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
    
    // Helper method to format error messages
    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        
        return errors
            .filter(error => !!error)
            .map(error => {
                // UI API read errors
                if (Array.isArray(error.body)) {
                    return error.body.map(e => e.message).join(', ');
                }
                // UI API DML, Apex and network errors
                else if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                }
                // JS errors
                else if (typeof error.message === 'string') {
                    return error.message;
                }
                // Unknown error shape so try HTTP status text
                return error.statusText ? error.statusText : JSON.stringify(error);
            })
            .join(', ');
    }
}