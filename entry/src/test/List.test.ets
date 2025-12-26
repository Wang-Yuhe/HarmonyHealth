import localUnitTest from './LocalUnit.test';
import performanceTest from './Performance.test';
import stabilityTest from './Stability.test';
import exceptionHandlingTest from './ExceptionHandling.test';

export default function testsuite() {
  localUnitTest();
  performanceTest();
  stabilityTest();
  exceptionHandlingTest();
}