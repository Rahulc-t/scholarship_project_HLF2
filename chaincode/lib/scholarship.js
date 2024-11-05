'use strict';

const { Contract } = require('fabric-contract-api');

class ScholarshipContract extends Contract {

    // Initialize the ledger with no students
    async initLedger(ctx) {
        console.log('Scholarship Ledger Initialized');
    }

    // University submits a list of students
    async submitStudentList(ctx, id, name, marks) {
        const clientMSP = ctx.clientIdentity.getMSPID();
    if (clientMSP !== 'universityMSP') {
      throw new Error('Only university MSP can add students.');
    }
        const student = {
            id,
            name,
            marks,
            status: 'Submitted', // Initial status after submission
            fundDisbursed: false // No funds disbursed initially
        };
        await ctx.stub.putState(id, Buffer.from(JSON.stringify(student)));
        return JSON.stringify(student);
    }

    // Scholarship Department verifies a student's eligibility
    async verifyStudent(ctx, id) {
        const clientMSP = ctx.clientIdentity.getMSPID();
    if (clientMSP !== 'scholarshipDepartmentMSP') {
      throw new Error('Only scholarship department MSP can verify students.');
    }
        const student = await this._getStudent(ctx, id);
        student.status = 'Verified';
        await ctx.stub.putState(id, Buffer.from(JSON.stringify(student)));
        return JSON.stringify(student);
    }

    // Scholarship Department rejects a student
    async rejectStudent(ctx, id) {
        const clientMSP = ctx.clientIdentity.getMSPID();
    if (clientMSP !== 'scholarshipDepartmentMSP') {
      throw new Error('Only scholarship department MSP can verify students.');
    }
        const student = await this._getStudent(ctx, id);
        student.status = 'Rejected';
        await ctx.stub.putState(id, Buffer.from(JSON.stringify(student)));
        return JSON.stringify(student);
    }

    // Process students: Verify those with marks >= 60, reject others
    // async processStudentDetails(ctx) {
    //     const queryString = {
    //         selector: {
    //             status: 'Submitted'
    //         }
    //     };
    //     const students = await this._getQueryResult(ctx, JSON.stringify(queryString));

    //     const processedResults = [];
    //     for (let student of students) {
    //         if (student.marks >= 60) {
    //             student.status = 'Verified';
    //         } else {
    //             student.status = 'Rejected';
    //         }
    //         await ctx.stub.putState(student.id, Buffer.from(JSON.stringify(student)));
    //         processedResults.push(student);
    //     }

    //     return JSON.stringify(processedResults);
    // }
    async processesStudents(ctx,id){
        const clientMSP = ctx.clientIdentity.getMSPID();
    if (clientMSP !== 'scholarshipDepartmentMSP') {
      throw new Error('Only scholarship department MSP can verify students.');
    }
        const student = await this._getStudent(ctx, id);
        if(student.marks>=60){
            student.status='Verified';
        }
        else{
            student.status='Rejected';
            }
            await ctx.stub.putState(id, Buffer.from(JSON.stringify(student)));

    }
    // Treasury disburses funds to verified students
    async disburseFunds(ctx, id) {
        const clientMSP = ctx.clientIdentity.getMSPID();
    if (clientMSP !== 'treasuryMSP') {
      throw new Error('Only treasury MSP can send funds.');
    }
        const student = await this._getStudent(ctx, id);
        if (student.status !== 'Verified') {
            throw new Error(`Student with ID ${id} is not verified, cannot disburse funds.`);
        }
        student.status = 'Funded';
        student.fundDisbursed = true;
        await ctx.stub.putState(id, Buffer.from(JSON.stringify(student)));
        return JSON.stringify(student);
    }

    // Auditor reviews the status of a student
    async queryStudent(ctx, id) {
        const student = await this._getStudent(ctx, id);
        return JSON.stringify(student);
    }

    // Auditor queries all rejected students
    async queryRejectedStudents(ctx) {
        const queryString = {
            selector: {
                status: 'Rejected'
            }
        };
        const rejectedStudents = await this._getQueryResult(ctx, JSON.stringify(queryString));
        return JSON.stringify(rejectedStudents);
    }

    // Treasury sends total disbursement amount to the Auditor via private data collection
    async submitTotalAmountToAuditor(ctx, totalAmount) {
        const clientMSP = ctx.clientIdentity.getMSPID();
    if (clientMSP !== 'treasuryMSP') {
      throw new Error('Only treasury MSP can submit this data.');
    }
        const auditorCollection = 'auditorPrivateCollection'; // Name of the private data collection
        const amountDetails = {
            totalAmount,
            timestamp: new Date().toISOString() // Track when the amount is submitted
        };
        await ctx.stub.putPrivateData(auditorCollection, 'totalAmount', Buffer.from(JSON.stringify(amountDetails)));
        return `Total amount of ${totalAmount} sent to Auditor.`;
    }

    // Auditor retrieves the total disbursement amount from the private data collection
    // async queryTotalAmountFromAuditor(ctx) {
    //     const auditorCollection = 'auditorPrivateCollection';
    //     const totalAmountData = await ctx.stub.getPrivateData(auditorCollection, 'totalAmount');

    //     if (!totalAmountData || totalAmountData.length === 0) {
    //         throw new Error('No total amount found in Auditor’s private data collection.');
    //     }
    //     return totalAmountData.toString('utf8');
    // }
    async queryTotalAmountFromAuditor(ctx) {
        const clientMSP = ctx.clientIdentity.getMSPID();
    if (clientMSP !== 'auditorMSP') {
      throw new Error('Only auditor MSP can view this data.');
    }
        const auditorCollection = 'auditorPrivateCollection';
        const totalAmountData = await ctx.stub.getPrivateData(auditorCollection, 'totalAmount');
    
        if (!totalAmountData || totalAmountData.length === 0) {
            throw new Error('No total amount found in Auditor’s private data collection.');
        }
    
        const totalAmountJSON = JSON.parse(totalAmountData.toString('utf8'));
        return `Total Amount = ${totalAmountJSON.totalAmount}, timestamp = ${totalAmountJSON.timestamp}`; // Fix: format the response
    }
    

    // Internal helper function to get the student data
    async _getStudent(ctx, id) {
        const studentJSON = await ctx.stub.getState(id); // Get the student details from the ledger
        if (!studentJSON || studentJSON.length === 0) {
            throw new Error(`Student with ID ${id} does not exist`);
        }
        return JSON.parse(studentJSON.toString());
    }

    // Internal helper to query the ledger with a custom selector
    async _getQueryResult(ctx, queryString) {
        const iterator = await ctx.stub.getQueryResult(queryString);
        const results = [];
        let res = await iterator.next();

        while (!res.done) {
            const result = res.value.value.toString('utf8');
            results.push(JSON.parse(result));
            res = await iterator.next();
        }

        await iterator.close(); // Close the iterator after processing all results
        return results;
    }
}

module.exports = ScholarshipContract;
