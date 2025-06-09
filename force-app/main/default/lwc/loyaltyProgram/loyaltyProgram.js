import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAllTierNames from '@salesforce/apex/RetailerBenefitController.getAllTierNames';
import getFilteredRetailerBenefits from '@salesforce/apex/RetailerBenefitController.getFilteredRetailerBenefits';
import getStatusPicklistValues from '@salesforce/apex/RetailerBenefitController.getStatusPicklistValues';
import updateRetailerBenefitStatuses from '@salesforce/apex/RetailerBenefitController.updateRetailerBenefitStatuses';
import getCurrentUserProfile from '@salesforce/apex/RetailerBenefitController.getCurrentUserProfile';

import LightningAlert from 'lightning/alert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import SheetJS from '@salesforce/resourceUrl/SheetJs';

export default class LoyaltyProgram extends NavigationMixin(LightningElement) {

    @track userProfile = '';
    @track selectedTier = '';
    @track selectedQuarter = '';
    @track yearInputField = new Date().getFullYear().toString();

    @track tierOptions = [];
    @track quarterOptions = [
        { label: 'Yearly', value: '' },
        { label: 'Q1', value: 'Q1' },
        { label: 'Q2', value: 'Q2' },
        { label: 'Q3', value: 'Q3' },
        { label: 'Q4', value: 'Q4' }
    ];
    @track yearOptions = [];

    @track columns = [];
    @track tableData = [];
    @track filteredTableData = [];
    @track rawRecords = [];

    @track statusOptions = [];
    @track draftValues = [];

    @track ismodalopen = false;
    @track modalInputValue = '';
    @track selectedBenefitRecordId;
    @track selectedBenefitField;

    @track searchKeyword = '';

    pendingModalInputs = [];

    @wire(getAllTierNames)
    wiredTiers({ data }) {
        if (data) {
            console.log('OUTPUT Data: ',data);
            
            this.tierOptions = [
                { label: 'All', value: '' },
                ...data.map(n => ({ label: n, value: n }))
            ];
            console.log('OUTPUT tierOptions: ',this.tierOptions);
        }
    }

    connectedCallback() {
        this.buildYearOptions();
        this.loadPicklistValues();
        this.getUserProfile();

        loadScript(this, SheetJS)
            .then(() => console.log('SheetJS loaded'))
            .catch(err => console.error('SheetJS load error', err));
    }

    buildYearOptions() {
        const current = new Date().getFullYear();
        const start = current - 10;
        const end = current + 60;
        this.yearOptions = Array.from({ length: end - start + 1 }, (_, i) => {
            const y = (start + i).toString();
            return { label: y, value: y };
        });
    }

    getUserProfile() {
        getCurrentUserProfile()
            .then(profile => {
                this.userProfile = profile;
                this.loadRetailerData();
            })
            .catch(err => console.error('Profile error', err));
    }

    async loadPicklistValues() {
        const vals = await getStatusPicklistValues();
        this.statusOptions = vals.map(v => ({ label: v, value: v }));
    }

    handleYearChange(e) { this.yearInputField = e.detail.value; this.loadRetailerData(); }
    handleTierChange(e) { this.selectedTier = e.detail.value; this.loadRetailerData(); }
    handleQuarterChange(e) { this.selectedQuarter = e.detail.value; this.loadRetailerData(); }

    handleRetailerSearch(e) {
        this.searchKeyword = (e.target.value || '').toLowerCase();
        this.applySearchFilter();
    }

    handleYearInput(e) {
        this.yearInputField = (e.target.value || '').replace(/\D/g, '');
        if (this.yearInputField.length === 4) this.loadRetailerData();
    }

    async loadRetailerData() {
        try {
            const result = await getFilteredRetailerBenefits({
                tierName   : this.selectedTier || null,
                quarterType: this.selectedQuarter,
                yearType: this.yearInputField
            });
            console.log('OUTPUT : ',result);
            console.log('selected Tier : ',this.selectedTier);

            const benefitSet = new Set();
            const retailerMap = new Map();
            const showTierCol = !this.selectedTier;

            result.forEach(w => {
                const b = w.benefit;
                const retailerId = b.Account__r.Id;
                const tierLabel = b.Account__r.Retailer_Tier__r?.Name || 'N/A';
                const suffix = b.Type__c === 'Yearly' ? 'Yearly'
                    : b.Type__c === 'One Time' ? 'One Time'
                        : b.Type__c;
                const benefitLbl = `${b.Benefit__r?.Name} (${suffix})`;

                benefitSet.add(benefitLbl);

                if (!retailerMap.has(retailerId)) {
                    retailerMap.set(retailerId, {
                        id: retailerId,
                        retailerName: b.Account__r.Name,
                        retailerUrl: '/' + retailerId,
                        ...(showTierCol && { retailerTier: tierLabel })
                    });
                }
                console.log('OUTPUT :retailerMap---- ',retailerMap);
                console.log('OUTPUT :selectedQuarter---- ',this.selectedQuarter);
                if (this.selectedQuarter) {
                    const purchase = w.purchaseAmount;
                    retailerMap.get(retailerId).purchaseAmount = purchase;
                    retailerMap.get(retailerId).purchaseAmountFormatted =
                        this.formatCurrency(purchase);
                }

                // 👇 Modified logic: display Link__c if status is YES and link is present
                let valueToDisplay = b.Status__c;
                if (b.Status__c === 'YES' && b.Link__c) {
                    valueToDisplay = b.Link__c;      
                }
                retailerMap.get(retailerId)[benefitLbl] = valueToDisplay;
                
            });

            const benefitBuckets = { 'One Time': [], 'Yearly': [], 'Quarter': [] };

            benefitSet.forEach(lbl => {
                if (lbl.includes('(One Time)')) benefitBuckets['One Time'].push(lbl);
                else if (lbl.includes('(Yearly)')) benefitBuckets['Yearly'].push(lbl);
                else benefitBuckets['Quarter'].push(lbl);
            });

            this.columns = [
                {
                    label: 'Retailer',
                    fieldName: 'retailerUrl',
                    type: 'url',
                    typeAttributes: {
                        label: { fieldName: 'retailerName' },
                        target: '_self'
                    }
                },
                ...(showTierCol ? [{
                    label: 'Tier',
                    fieldName: 'retailerTier'
                }] : []),
                ...(this.selectedQuarter ? [{
                    label: `${this.selectedQuarter} Purchase Amount`,
                    fieldName: 'purchaseAmountFormatted',
                    cellAttributes: { alignment: 'left' }
                }] : []),
                ...benefitBuckets['One Time'].map(b => this.createBenefitColumn(b)),
                ...benefitBuckets['Yearly'].map(b => this.createBenefitColumn(b)),
                ...(this.selectedQuarter
                    ? benefitBuckets['Quarter'].map(b => this.createBenefitColumn(b))
                    : [])
            ];

            this.tableData = Array.from(retailerMap.values()).map(r => {
                benefitSet.forEach(b => { if (!(b in r)) r[b] = ''; });
                return r;
            });
            console.log('OUTPUT : tableData--- ',this.tableData);

            this.rawRecords = result.map(w => w.benefit);
            console.log('OUTPUT : rawRecords--- ',this.rawRecords);

            this.draftValues = [];
            this.applySearchFilter();
        } catch (e) {
            console.error('load error', e);
            this.showToast('Error', 'Could not load data', 'error');
        }
    }

    applySearchFilter() {
        if (!this.searchKeyword) {
            this.filteredTableData = [...this.tableData];
            return;
        }
        const kw = this.searchKeyword;
        this.filteredTableData = this.tableData.filter(r =>
            r.retailerName.toLowerCase().includes(kw)
        );
    }

    formatCurrency(num) {
        if (num === null || num === undefined) return '₹0';
        return num.toLocaleString('en-IN', { maximumFractionDigits: 0 });
    }


    createBenefitColumn(label) {
        const editable = this.userProfile !== 'Community Distributor Access';
        const v = (label !== 'YES' && label !== 'NO') ? 'Url' : 'text';

        return {
            label,
            fieldName: label, // field that stores the link (or empty string)
            type: v,
            editable,
            typeAttributes: {
                label: { fieldName: `${label}_label` }, // label is the URL itself
                target: '_blank'
            }
           
        };
    }
        

    handleCellChange(event) {
        const draft = event.detail.draftValues[0];
        const existing = this.draftValues.find(d => d.id === draft.id);
        if (existing) Object.assign(existing, draft);
        else this.draftValues.push(draft);

        for (const key of Object.keys(draft)) {
            if (key === 'id') continue;
            draft[key] = typeof draft[key] === 'string' ? draft[key].toUpperCase() : draft[key];

            if (draft[key] === 'YES') {
                const benefitName = key.split(' (')[0];
                const record = this.rawRecords.find(r =>
                    r.Account__r.Id === draft.id && r.Benefit__r.Name === benefitName
                );
                if (record?.Benefit__r?.Link_Required__c) {
                    this.selectedBenefitRecordId = draft.id;
                    this.selectedBenefitField = key;
                    this.modalInputValue = '';
                    this.ismodalopen = true;
                    break;
                }
            }
        }
    }

    handleInputFieldChange(e) {
        this.modalInputValue = e.target.value;
    }

    closeModal() {
        this.ismodalopen = false;
    }

    submit() {
        if (!this.modalInputValue.trim()) {
            LightningAlert.open({ message: 'Please fill the input field', theme: 'error' });
            return;
        }

        const idx = this.draftValues.findIndex(d => d.id === this.selectedBenefitRecordId);

        if (idx !== -1) {
            const upd = { ...this.draftValues[idx] };
            upd[this.selectedBenefitField] = this.modalInputValue;

            const updatedDraftValues = [...this.draftValues];
            updatedDraftValues.splice(idx, 1, upd);
            this.draftValues = updatedDraftValues;

            this.pendingModalInputs.push({
                id: this.selectedBenefitRecordId,
                benefitField: this.selectedBenefitField,
                linkValue: this.modalInputValue
            });
        }

        this.ismodalopen = false;
    }

    async handleSave() {
        const updates = [];

        for (const draft of this.draftValues) {
            const retailerId = draft.id;

            for (const key of Object.keys(draft)) {
                if (['id', 'retailerName', 'retailerTier', 'retailerUrl'].includes(key)) continue;

                const benefitName = key.split(' (')[0];
                const rec = this.rawRecords.find(r =>
                    r.Account__r.Id === retailerId && r.Benefit__r.Name === benefitName
                );
                if (!rec) continue;

                const modalInput = this.pendingModalInputs.find(i =>
                    i.id === draft.id && i.benefitField === key
                );

                const statusValue = modalInput ? 'YES' : draft[key];

                const upd = {
                    Id: rec.Id,
                    Status__c: statusValue
                };

                if (modalInput) {
                    upd.Link__c = modalInput.linkValue;
                }
                updates.push(upd);
            }
        }

        if (updates.length === 0) {
            this.showToast('No Changes', 'There are no changes to save.', 'info');
            return;
        }

        try {
            await updateRetailerBenefitStatuses({ updatedBenefits: updates });
            this.showToast('Success', 'Benefit Status updated successfully!', 'success');
            await this.loadRetailerData();
            this.applySearchFilter();
            this.draftValues = [];
            this.pendingModalInputs = [];
        } catch (e) {
            console.error('Save error', e);
            this.showToast('Error', 'Error updating benefits.', 'error');
        }
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }

    exportToExcel() {
        if (!window.XLSX) {
            this.showToast('Error', 'Excel library not loaded.', 'error');
            return;
        }

        const data = this.filteredTableData;
        if (!data.length) {
            this.showToast('No Data', 'There is no data to export.', 'info');
            return;
        }

        const exportData = data.map(record => {
            const cleaned = { ...record };
            delete cleaned.id;
            delete cleaned.retailerUrl;
            return cleaned;
        });

        const worksheet = XLSX.utils.json_to_sheet(exportData);
        const workbook = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(workbook, worksheet, 'Retailer Benefits');

        const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
        const blob = new Blob([excelBuffer], { type: 'application/octet-stream' });

        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = `Retailer_Benefits_${new Date().toISOString().split('T')[0]}.xlsx`;
        a.click();
        URL.revokeObjectURL(a.href);
    }
}