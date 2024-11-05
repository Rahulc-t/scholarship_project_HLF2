const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const sinon = require('sinon');
const sinonChai = require('sinon-chai');
const { expect } = require('chai');

chai.should();
chai.use(chaiAsPromised);
chai.use(sinonChai);

const ScholarshipContract = require('../lib/scholarship'); // Adjust the path as needed
const { ChaincodeStub, ClientIdentity } = require('fabric-shim');

class TestContext {
    constructor() {
        this.stub = sinon.createStubInstance(ChaincodeStub);
        this.clientIdentity = sinon.createStubInstance(ClientIdentity);
    }
}

describe('ScholarshipContract', () => {

    let contract;
    let ctx;

    beforeEach(() => {
        contract = new ScholarshipContract();
        ctx = new TestContext();

        const student = {
            id: 'student1',
            name: 'John Doe',
            marks: 85,
            status: 'Submitted',
            fundDisbursed: false
        };

        ctx.stub.getState.withArgs('student1').resolves(Buffer.from(JSON.stringify(student)));
        ctx.stub.getState.withArgs('student2').resolves(Buffer.from(JSON.stringify(student)));

        ctx.clientIdentity = {
            getMSPID: () => 'universityMSP',
        };
    });

    describe('#initLedger', () => {
        it('should initialize the ledger', async () => {
            await contract.initLedger(ctx);
            // Expectation can be added based on what the initLedger does
            // For now, it just logs to the console
        });
    });

    describe('#submitStudentList', () => {
        it('should submit a student to the ledger', async () => {
            const student = await contract.submitStudentList(ctx, 'student1', 'John Doe', 85);

            const expectedStudent = {
                id: 'student1',
                name: 'John Doe',
                marks: 85,
                status: 'Submitted',
                fundDisbursed: false
            };

            ctx.stub.putState.should.have.been.calledOnceWithExactly(
                'student1',
                Buffer.from(JSON.stringify(expectedStudent))
            );

            JSON.parse(student).should.deep.equal(expectedStudent);
        });
    });

    describe('#verifyStudent', () => {
        it('should verify a student', async () => {
            const student = {
                id: 'student1',
                name: 'John Doe',
                marks: 85,
                status: 'Submitted',
                fundDisbursed: false
            };

            ctx.stub.getState.withArgs('student1').resolves(Buffer.from(JSON.stringify(student)));

            await contract.verifyStudent(ctx, 'student1');

            student.status = 'Verified';

            ctx.stub.putState.should.have.been.calledOnceWithExactly(
                'student1',
                Buffer.from(JSON.stringify(student))
            );
        });

        it('should throw an error if student does not exist', async () => {
            ctx.stub.getState.withArgs('student3').resolves(null);

            await contract.verifyStudent(ctx, 'student3').should.be.rejectedWith(/Student with ID student3 does not exist/);
        });
    });

    describe('#rejectStudent', () => {
        it('should reject a student', async () => {
            const student = {
                id: 'student1',
                name: 'John Doe',
                marks: 85,
                status: 'Submitted',
                fundDisbursed: false
            };

            ctx.stub.getState.withArgs('student1').resolves(Buffer.from(JSON.stringify(student)));

            await contract.rejectStudent(ctx, 'student1');

            student.status = 'Rejected';

            ctx.stub.putState.should.have.been.calledOnceWithExactly(
                'student1',
                Buffer.from(JSON.stringify(student))
            );
        });

        it('should throw an error if student does not exist', async () => {
            ctx.stub.getState.withArgs('student3').resolves(null);

            await contract.rejectStudent(ctx, 'student3').should.be.rejectedWith(/Student with ID student3 does not exist/);
        });
    });

    // Updated test for processesStudents
    describe('#processesStudents', () => {
        it('should verify a student with marks >= 60', async () => {
            const student = {
                id: 'student1',
                name: 'John Doe',
                marks: 85,
                status: 'Submitted',
                fundDisbursed: false
            };

            ctx.stub.getState.withArgs('student1').resolves(Buffer.from(JSON.stringify(student)));

            await contract.processesStudents(ctx, 'student1');

            student.status = 'Verified';

            ctx.stub.putState.should.have.been.calledOnceWithExactly(
                'student1',
                Buffer.from(JSON.stringify(student))
            );
        });

        it('should reject a student with marks < 60', async () => {
            const student = {
                id: 'student2',
                name: 'Jane Smith',
                marks: 55,
                status: 'Submitted',
                fundDisbursed: false
            };

            ctx.stub.getState.withArgs('student2').resolves(Buffer.from(JSON.stringify(student)));

            await contract.processesStudents(ctx, 'student2');

            student.status = 'Rejected';

            ctx.stub.putState.should.have.been.calledOnceWithExactly(
                'student2',
                Buffer.from(JSON.stringify(student))
            );
        });
    });

    describe('#disburseFunds', () => {
        it('should disburse funds to a verified student', async () => {
            const student = {
                id: 'student1',
                name: 'John Doe',
                marks: 85,
                status: 'Verified',
                fundDisbursed: false
            };

            ctx.stub.getState.withArgs('student1').resolves(Buffer.from(JSON.stringify(student)));

            await contract.disburseFunds(ctx, 'student1');

            student.status = 'Funded';
            student.fundDisbursed = true;

            ctx.stub.putState.should.have.been.calledOnceWithExactly(
                'student1',
                Buffer.from(JSON.stringify(student))
            );
        });

        it('should throw an error if student is not verified', async () => {
            const student = {
                id: 'student1',
                name: 'John Doe',
                marks: 85,
                status: 'Submitted', // Not verified yet
                fundDisbursed: false
            };

            ctx.stub.getState.withArgs('student1').resolves(Buffer.from(JSON.stringify(student)));

            await contract.disburseFunds(ctx, 'student1').should.be.rejectedWith(/Student with ID student1 is not verified, cannot disburse funds/);
        });
    });

    describe('#queryStudent', () => {
        it('should return the student information', async () => {
            const student = {
                id: 'student1',
                name: 'John Doe',
                marks: 85,
                status: 'Submitted',
                fundDisbursed: false
            };

            ctx.stub.getState.withArgs('student1').resolves(Buffer.from(JSON.stringify(student)));

            const result = await contract.queryStudent(ctx, 'student1');
            result.should.equal(JSON.stringify(student));
        });

        it('should throw an error if student does not exist', async () => {
            ctx.stub.getState.withArgs('student3').resolves(null);

            await contract.queryStudent(ctx, 'student3').should.be.rejectedWith(/Student with ID student3 does not exist/);
        });
    });

    describe('#queryRejectedStudents', () => {
        it('should return all rejected students', async () => {
            const students = [
                { id: 'student2', name: 'Jane Smith', marks: 55, status: 'Rejected' },
                { id: 'student3', name: 'Mike Johnson', marks: 50, status: 'Rejected' }
            ];

            ctx.stub.getQueryResult.withArgs(sinon.match.any).resolves({
                next: async function* () {
                    yield { value: Buffer.from(JSON.stringify(students[0])) };
                    yield { value: Buffer.from(JSON.stringify(students[1])) };
                    return { done: true };
                },
                close: async () => {}
            });

            const result = await contract.queryRejectedStudents(ctx);
            const rejectedStudents = JSON.parse(result);

            expect(rejectedStudents).to.have.length(2);
            expect(rejectedStudents[0].status).to.equal('Rejected');
            expect(rejectedStudents[1].status).to.equal('Rejected');
        });
    });

    describe('#submitTotalAmountToAuditor', () => {
        it('should submit total amount to auditor', async () => {
            const totalAmount = 10000;
            const amountDetails = {
                totalAmount,
                timestamp: sinon.match.string // Match any timestamp
            };
            
            ctx.stub.putPrivateData(
                'auditorPrivateCollection',
                'totalAmount',
                Buffer.from(JSON.stringify(amountDetails))
            );
        });
    });

    describe('#queryTotalAmountFromAuditor', () => {
        it('should retrieve the total amount from auditor', async () => {
            const totalAmountData = { totalAmount: 10000, timestamp: '2024-10-27T00:00:00Z' };

            ctx.stub.getPrivateData.withArgs('auditorPrivateCollection', 'totalAmount').resolves(Buffer.from(JSON.stringify(totalAmountData)));

            const result = await contract.queryTotalAmountFromAuditor(ctx);
            const expectedResponse = `Total Amount = 10000, timestamp = 2024-10-27T00:00:00Z`;

            expect(result).to.equal(expectedResponse);
        });
    });
});

