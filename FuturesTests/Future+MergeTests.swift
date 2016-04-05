import Quick
import Nimble
import PiedPiper

class FutureSequenceMergeTests: QuickSpec {
  override func spec() {
    describe("Merging a list of Futures") {
      var promises: [Promise<Int>]!
      var mergedFuture: Future<[Int]>!
      var successValue: [Int]?
      var failureValue: ErrorType?
      var wasCanceled: Bool!
      
      beforeEach {
        promises = [
          Promise(),
          Promise(),
          Promise(),
          Promise(),
          Promise()
        ]
        
        wasCanceled = false
        successValue = nil
        failureValue = nil
        
        mergedFuture = promises
          .map { $0.future }
          .merge()
        
        mergedFuture.onCompletion { result in
          switch result {
          case .Success(let value):
            successValue = value
          case .Error(let error):
            failureValue = error
          case .Cancelled:
            wasCanceled = true
          }
        }
      }
      
      context("when one of the original futures fails") {
        let expectedError = TestError.AnotherError
        
        beforeEach {
          promises.first?.succeed(10)
          promises[1].fail(expectedError)
        }
        
        it("should fail the merged future") {
          expect(failureValue).notTo(beNil())
        }
        
        it("should fail with the right error") {
          expect(failureValue as? TestError).to(equal(expectedError))
        }
        
        it("should not cancel the merged future") {
          expect(wasCanceled).to(beFalse())
        }
        
        it("should not succeed the merged future") {
          expect(successValue).to(beNil())
        }
      }
      
      context("when one of the original futures is canceled") {
        beforeEach {
          promises.first?.succeed(10)
          promises[1].cancel()
        }
        
        it("should not fail the merged future") {
          expect(failureValue).to(beNil())
        }
        
        it("should cancel the merged future") {
          expect(wasCanceled).to(beTrue())
        }
        
        it("should not succeed the merged future") {
          expect(successValue).to(beNil())
        }
      }
      
      context("when all the original futures succeed") {
        var expectedResult: [Int]!
        
        context("when they succeed in the same order") {
          beforeEach {
            expectedResult = promises.enumerate().map { $0.index }
            promises.enumerate().forEach { (iteration, promise) in
              promise.succeed(iteration)
            }
          }
          
          it("should not fail the merged future") {
            expect(failureValue).to(beNil())
          }
          
          it("should not cancel the merged future") {
            expect(wasCanceled).to(beFalse())
          }
          
          it("should succeed the merged future") {
            expect(successValue).notTo(beNil())
          }
          
          it("should succeed with the right value") {
            expect(successValue).to(equal(expectedResult))
          }
        }
      }
    }
    
    describe("Merging a list of Futures, independently of the order they succeed") {
      var promises: [Promise<String>]!
      var mergedFuture: Future<[String]>!
      var successValue: [String]?
      var expectedResult: [String]!
      
      beforeEach {
        promises = [
          Promise(),
          Promise(),
          Promise(),
          Promise(),
          Promise()
        ]
        
        successValue = nil
        
        mergedFuture = promises
          .map { $0.future }
          .merge()
        
        mergedFuture.onSuccess {
          successValue = $0
        }
        
        expectedResult = Array(0..<promises.count).map { "\($0)" }
        
        var arrayOfIndexes = Array(promises.enumerate())
        
        repeat {
          arrayOfIndexes = arrayOfIndexes.shuffle()
        } while arrayOfIndexes.map({ $0.0 }) == Array(0..<promises.count)
        
        arrayOfIndexes.forEach { (originalIndex, promise) in
          promise.succeed("\(originalIndex)")
        }
      }
      
      it("should succeed the merged future") {
        expect(successValue).notTo(beNil())
      }
      
      it("should succeed with the right value") {
        expect(successValue).to(equal(expectedResult))
      }
    }
  }
}