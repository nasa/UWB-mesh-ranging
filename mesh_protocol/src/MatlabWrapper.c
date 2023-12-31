#include "../include/MatlabWrapper.h"

/** initialize the wrapper by initializing arrays 
*   and generating an initial random seed for every node; the random seeds are generated by using the one 
*   seed that was provided by MATLAB
*/
Wrapper init(uint32_t seed) {
  Wrapper self = calloc(1, sizeof(WrapperStruct));
  self->numNodes = 0;

  for(int i = 0; i < (MAX_NUM_NODES); ++i) {
      self->localTimes[i] = 0;
      self->lastTxStartTimes[i] = -1;
      self->txFinished[i] = true; // initialize to true to signal that there is no transmission going on
      self->lastSkewTime[i] = 0;
  };

  /** simple way to define clock skews
  * the value here means "add one additional tic every VALUE tics" if it is positive 
  * or "skip the tic every VALUE tics" if the value is negative
  */
  self->clockSkew[0] = 5000;
  self->clockSkew[1] = -5000;
  self->clockSkew[2] = 10000;
  self->clockSkew[3] = -10000;

  // seed the RNG once and generate a random seed for every node
  mexPrintf("Seed: %" PRIu32 "\n", seed);
  srand(seed);
  for(int i = 0; i < (MAX_NUM_NODES); ++i) {
    // generate a random number between 100,000,000 and 999,999,999; from http://c-faq.com/lib/randrange.html
    self->initialRandomSeeds[i] = (uint32_t) (100000000 + rand()/ (RAND_MAX / (999999999 - 100000000 + 1) + 1)); 
  };

  return self;
};

int8_t Wrapper_AddNode(Wrapper wrapper, Node node) {
  wrapper->nodes[wrapper->numNodes] = node;
  wrapper->ids[wrapper->numNodes] = node->id;
  return ++wrapper->numNodes;
};

int8_t Wrapper_GetNumNodes(Wrapper wrapper) {
  return wrapper->numNodes;
};

Node createNode(int16_t id, Message *msgOut, bool *txFinished, bool *isReceiving, int64_t *localTime, uint32_t seed) {
  // create all the structs that hold the data of the node
  Node node = Node_Create();
  StateMachine stateMachine = StateMachine_Create();
  Scheduler scheduler = Scheduler_Create();
  ProtocolClock clock = ProtocolClock_Create(localTime);
  TimeKeeping timeKeeping = TimeKeeping_Create();
  NetworkManager networkManager = NetworkManager_Create();
  MessageHandler messageHandler = MessageHandler_Create();
  SlotMap slotMap = SlotMap_Create();
  Neighborhood neighborhood = Neighborhood_Create();
  RangingManager rangingManager = RangingManager_Create();
  LCG lcg = LCG_Create(seed);
  Config config = Config_Create();
  Driver driver = Driver_Create(txFinished, isReceiving);

  // set the structs as pointers for the Node struct, so we only have to pass around the Node struct
  Node_SetDriver(node, driver);
  Driver_SetOutMsgAddress(node, msgOut);

  Node_SetStateMachine(node, stateMachine);
  Node_SetScheduler(node, scheduler);
  Node_SetClock(node, clock);
  Node_SetTimeKeeping(node, timeKeeping);
  Node_SetNetworkManager(node, networkManager);
  Node_SetMessageHandler(node, messageHandler);
  Node_SetSlotMap(node, slotMap);
  Node_SetNeighborhood(node, neighborhood);
  Node_SetRangingManager(node, rangingManager);
  Node_SetLCG(node, lcg);
  Node_SetConfig(node, config);

  node->id = id;
  return node;
};

/** run the state machine with time tic as parameter */
bool runStateMachineTimeTic(Node node) {
  // only node necessary as parameter because this is only called on time tics
  StateMachine_Run(node, TIME_TIC, NULL);

  // return if the node sent a message
  return node->driver->sentMessage;
};

/** run the state machine with incoming msg as parameter */
bool runStateMachineIncomingMsg(Node node, Message msg) {
  StateMachine_Run(node, INCOMING_MSG, msg);

  // return if the node sent a message
  return node->driver->sentMessage;
};

/** turn the node on */
void turnOnNode(Node node) {
  /* TURN_ON will trigger the state transition from OFF to LISTENING_UNCONNECTED */
  StateMachine_Run(node, TURN_ON, NULL);
};

/** this is the function that will be executed when in MATLAB the mex-file is called */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  
  /** MATLAB can run different functions from the same mex-file by providing different arguments;
  * the first argument is the number of the function to be called which will be evaluated in the remainder of this function
  */

  // first evaluate which function to call
  int functionId = mxGetScalar(prhs[0]);

  /** INIT
  *   This function creates the MatlabWrapper for the simulation and returns its memory address back to MATLAB,
  *   so MATLAB can use the memory address as an argument in subsequent calls and this C code can access the same wrapper 
  *   with all data again by just creating a Wrapper-pointer to that address. 
  *   This is essential to have a simulation that can be controlled by MATLAB.
  */
  if (functionId == 1) { // init

    // check number of inputs and outputs
    if(nrhs != 2) {
      mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Two inputs required (function to call, random seed).");
    };

    // get the random seed from the arguments (is the second argument)
    int32_t seed;
    seed = mxGetScalar(prhs[1]);

    long long * out;
    plhs[0] = mxCreateNumericMatrix(1,1,mxINT64_CLASS,mxREAL);
    out = (long long *) mxGetData(plhs[0]);

    // call function to initialize the MatlabWrapper
    Wrapper wrapper;
    wrapper = init(seed);

    // return the actual memory address of this Wrapper back to MATLAB, so it can be used in subsequent calls
    // to access the same simulation again
    *out = (long long) wrapper;



    /** CREATE NODE
    *   Create a new node and add it to the wrapper
    */
  } else if (functionId == 2) { // create node
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Three inputs required (function to call, wrapper address, node ID).");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);

    // call function
    int8_t numNodes = Wrapper_GetNumNodes(wrapper);
    Node node = createNode(id, &wrapper->outMsg[numNodes], &wrapper->txFinished[numNodes], &wrapper->isReceiving[numNodes], &wrapper->localTimes[numNodes], wrapper->initialRandomSeeds[numNodes]);
    Wrapper_AddNode(wrapper, node);
    plhs[0] = mxCreateDoubleScalar(Wrapper_GetNumNodes(wrapper));



  /** RUN STATE MACHINE TIME TIC
  *   Run the state machine of a node one time with TIME_TIC as argument
  */
  } else if (functionId == 3) { // runStateMachineTimeTic
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Three inputs required (function to call, wrapper address, node ID).");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);
    
    // get the Node struct of the node whose state machine should be run
    int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
    Node node = wrapper->nodes[nodeIdx];

    // check if a prior transmission is finished now
    int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
    int64_t txFinishedTime = (wrapper->lastTxStartTimes[nodeIdx] + wrapper->lastTxMsgSize[nodeIdx]);

    if (localTime >= txFinishedTime && (wrapper->lastTxStartTimes[nodeIdx] != -1)) {
      *node->driver->txFinishedFlag = true;
    };

    // run the state machine
    bool msgSent = runStateMachineTimeTic(node);

    // convert message the node may have sent into Matlab message struct that can be returned
    // if no message was sent, the type will later be set to -1 to signal this to MATLAB
    Message msg = *node->driver->msgOutAddress;

    // assign field names
    char *fieldnames[11];
    fieldnames[0] = (char*)mxMalloc(20);
    fieldnames[1] = (char*)mxMalloc(20);
    fieldnames[2] = (char*)mxMalloc(20);
    fieldnames[3] = (char*)mxMalloc(20);
    fieldnames[4] = (char*)mxMalloc(20);
    fieldnames[5] = (char*)mxMalloc(22);
    fieldnames[6] = (char*)mxMalloc(20);
    fieldnames[7] = (char*)mxMalloc(20);
    fieldnames[8] = (char*)mxMalloc(20);
    fieldnames[9] = (char*)mxMalloc(20);
    fieldnames[10] = (char*)mxMalloc(20);

    memcpy(fieldnames[0],"type",sizeof("type"));
    memcpy(fieldnames[1],"senderId", sizeof("senderId"));
    memcpy(fieldnames[2],"timestamp",sizeof("timestamp"));
    memcpy(fieldnames[3],"networkId",sizeof("networkId"));
    memcpy(fieldnames[4],"networkAge",sizeof("networkAge"));
    memcpy(fieldnames[5],"timeSinceFrameStart",sizeof("timeSinceFrameStart"));
    memcpy(fieldnames[6],"oneHopSlotStatus",sizeof("oneHopSlotStatus"));
    memcpy(fieldnames[7],"oneHopSlotIds",sizeof("oneHopSlotIds"));
    memcpy(fieldnames[8],"twoHopSlotStatus",sizeof("twoHopSlotStatus"));
    memcpy(fieldnames[9],"twoHopSlotIds",sizeof("twoHopSlotIds"));
    memcpy(fieldnames[10],"recipientId",sizeof("recipientId"));

    // allocate memory for the structure
    plhs[0] = mxCreateStructMatrix(1,1,13,fieldnames);

    // deallocate memory for the fieldnames
    mxFree( fieldnames[0] );
    mxFree( fieldnames[1] );
    mxFree( fieldnames[2] );
    mxFree( fieldnames[3] );
    mxFree( fieldnames[4] );
    mxFree( fieldnames[5] );
    mxFree( fieldnames[6] );
    mxFree( fieldnames[7] );
    mxFree( fieldnames[8] );
    mxFree( fieldnames[9] );
    mxFree( fieldnames[10] );

    if (msgSent) {
      // assign the field values
      mxArray *type = mxCreateDoubleScalar(msg->type);
      mxArray *senderId = mxCreateDoubleScalar(msg->senderId);
      mxArray *timestamp = mxCreateDoubleScalar(msg->timestamp);
      mxArray *networkId = mxCreateDoubleScalar(msg->networkId);
      mxArray *networkAge = mxCreateDoubleScalar(msg->networkAge);
      mxArray *timeSinceFrameStart = mxCreateDoubleScalar(msg->timeSinceFrameStart);
      mxArray *oneHopSlotStatus = mxCreateNumericMatrix(1,NUM_SLOTS,mxINT32_CLASS,mxREAL);
      mxArray *oneHopSlotIds = mxCreateNumericMatrix(1,NUM_SLOTS,mxINT8_CLASS,mxREAL);
      mxArray *twoHopSlotStatus = mxCreateNumericMatrix(1,NUM_SLOTS,mxINT32_CLASS,mxREAL);
      mxArray *twoHopSlotIds = mxCreateNumericMatrix(1,NUM_SLOTS,mxINT8_CLASS,mxREAL);
      mxArray *recipientId = mxCreateDoubleScalar(msg->recipientId);

      // copy data to the mxArrays; 
      // do not free the array, because plhs[0] points to that data (see in Matlab: edit([matlabroot '/extern/examples/refbook/arrayFillSetData.c']);)
      // memory should be freed by MATLAB when this function returns
   
      int32_t *dataOneHopSlotStatus; 
      dataOneHopSlotStatus = mxCalloc(NUM_SLOTS, sizeof(int32_t));
      for (int elem = 0; elem < NUM_SLOTS; ++elem) {
        dataOneHopSlotStatus[elem] = msg->oneHopSlotStatus[elem];
      };

      int8_t *dataOneHopSlotIds; 
      dataOneHopSlotIds = mxCalloc(NUM_SLOTS, sizeof(int8_t));
      for (int elem = 0; elem < NUM_SLOTS; ++elem) {
        dataOneHopSlotIds[elem] = msg->oneHopSlotIds[elem];
      };

      int32_t *dataTwoHopSlotStatus; 
      dataTwoHopSlotStatus = mxCalloc(NUM_SLOTS, sizeof(int32_t));
      for (int elem = 0; elem < NUM_SLOTS; ++elem) {
        dataTwoHopSlotStatus[elem] = msg->twoHopSlotStatus[elem];
      };

      int8_t *dataTwoHopSlotIds; 
      dataTwoHopSlotIds = mxCalloc(NUM_SLOTS, sizeof(int8_t));
      for (int elem = 0; elem < NUM_SLOTS; ++elem) {
        dataTwoHopSlotIds[elem] = msg->twoHopSlotIds[elem];
      };

      mxSetData(oneHopSlotStatus, dataOneHopSlotStatus);
      mxSetData(oneHopSlotIds, dataOneHopSlotIds);
      mxSetData(twoHopSlotStatus, dataTwoHopSlotStatus);
      mxSetData(twoHopSlotIds, dataTwoHopSlotIds);

      mxSetFieldByNumber(plhs[0],0,0, type);
      mxSetFieldByNumber(plhs[0],0,1, senderId);
      mxSetFieldByNumber(plhs[0],0,2, timestamp);
      mxSetFieldByNumber(plhs[0],0,3, networkId);
      mxSetFieldByNumber(plhs[0],0,4, networkAge);
      mxSetFieldByNumber(plhs[0],0,5, timeSinceFrameStart);
      mxSetFieldByNumber(plhs[0],0,6, oneHopSlotStatus);
      mxSetFieldByNumber(plhs[0],0,7, oneHopSlotIds);
      mxSetFieldByNumber(plhs[0],0,8, twoHopSlotStatus);
      mxSetFieldByNumber(plhs[0],0,9, twoHopSlotIds);
      mxSetFieldByNumber(plhs[0],0,10, recipientId);
    
      // record the time when the message was sent to be able to signal when the transmission is over
      *node->driver->txFinishedFlag = false;
      wrapper->lastTxStartTimes[nodeIdx] = ProtocolClock_GetLocalTime(node->clock);
      switch (msg->type) {
        case PING: ;
          wrapper->lastTxMsgSize[nodeIdx] = PING_SIZE;
          break;
        case POLL: ;
          wrapper->lastTxMsgSize[nodeIdx] = POLL_SIZE;
          break;
        case RESPONSE: ;
          wrapper->lastTxMsgSize[nodeIdx] = RESPONSE_SIZE;
          break;
        case FINAL: ;
          wrapper->lastTxMsgSize[nodeIdx] = FINAL_SIZE;
          break;
        case RESULT: ;
          wrapper->lastTxMsgSize[nodeIdx] = RESULT_SIZE;
          break;
      };

      // set the sentMessage flag to false again
      node->driver->sentMessage = false;

      // free the memory of the message 
      // (the content of the message has been copied to an mxStruct, so this memory can be free'd safely)
      free(*node->driver->msgOutAddress);

    } else {
      // set type of message to -1 to signal that no message was sent
      mxArray *type = mxCreateDoubleScalar(-1);
      mxSetFieldByNumber(plhs[0],0,0, type);
    };




  /** RUN STATE MACHINE INCOMING MSG
  *   Run the state machine of a node one time with an incoming message as argument
  */
  } else if (functionId == 4) { // runStateMachineIncomingMsg
    // check number of inputs and outputs
    if(nrhs != 6) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Six inputs required (function to call, wrapper address, receiving node ID, sending node ID, timestamp, message struct).");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    // ID of the receiving node:
    int16_t idReceiving;
    idReceiving = mxGetScalar(prhs[2]);

    // ID of the sending node:
    int16_t idSending;
    idSending = mxGetScalar(prhs[3]);
    
    // get the node structs of both nodes
    int16_t nodeIdxReceiving = Util_Int8tArrayFindElement(&wrapper->ids[0], idReceiving, wrapper->numNodes);
    Node nodeReceiving = wrapper->nodes[nodeIdxReceiving];

    int16_t nodeIdxSending = Util_Int8tArrayFindElement(&wrapper->ids[0], idSending, wrapper->numNodes);
    Node nodeSending = wrapper->nodes[nodeIdxSending];

    // get message from the inputs
    // get all values from the input
    double *type = mxGetPr(mxGetFieldByNumber(prhs[5], 0, 0));
    double *senderId = mxGetPr(mxGetFieldByNumber(prhs[5], 0, 1));
    double *timestamp = mxGetPr(mxGetFieldByNumber(prhs[5], 0, 2));
    double *networkId = mxGetPr(mxGetFieldByNumber(prhs[5], 0, 3));
    double *networkAge = mxGetPr(mxGetFieldByNumber(prhs[5], 0, 4));
    double *timeSinceFrameStart = mxGetPr(mxGetFieldByNumber(prhs[5], 0, 5));

    mxArray *oneHopSlotStatus = mxGetFieldByNumber(prhs[5], 0, 6);
    mxInt32 *oneHopSlotStatusValues = mxGetInt32s(oneHopSlotStatus);
    mxArray *oneHopSlotIds = mxGetFieldByNumber(prhs[5], 0, 7);
    mxInt8 *oneHopSlotIdsValues = mxGetInt8s(oneHopSlotIds);
    mxArray *twoHopSlotStatus = mxGetFieldByNumber(prhs[5], 0, 8);
    mxInt32 *twoHopSlotStatusValues = mxGetInt32s(twoHopSlotStatus);
    mxArray *twoHopSlotIds = mxGetFieldByNumber(prhs[5], 0, 9);
    mxInt8 *twoHopSlotIdsValues = mxGetInt8s(twoHopSlotIds);
    double *recipientId = mxGetPr(mxGetFieldByNumber(prhs[5], 0, 10));

    // create a new msg out of the values that can be fed into the state machine
    int mtype = (int) *type;
    Message msg = Message_Create(mtype);

    msg->senderId = (int8_t) *senderId;
    msg->timestamp = (int64_t) *timestamp;
    msg->networkId = (uint8_t) *networkId;
    msg->networkAge = (int64_t) *networkAge;
    msg->timeSinceFrameStart = (int64_t) *timeSinceFrameStart;
    msg->recipientId = (int8_t) *recipientId;

    for (mwSize i = 0; i < NUM_SLOTS; ++i) {
      msg->oneHopSlotStatus[i] = oneHopSlotStatusValues[i];
      msg->oneHopSlotIds[i] = oneHopSlotIdsValues[i];
      msg->twoHopSlotStatus[i] = twoHopSlotStatusValues[i];
      msg->twoHopSlotIds[i] = twoHopSlotIdsValues[i];
    };

    // run the state machine
    runStateMachineIncomingMsg(nodeReceiving, msg);

    // free the memory of the message
    Message_Destroy(msg);


  /** TURN ON A NODE */
  } else if (functionId == 5) { // turnOnNode
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);
    
    // get the node struct of the node that should be turned on
    int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
    Node node = wrapper->nodes[nodeIdx];

    // turn the node on
    turnOnNode(node);



  /** RUN STATE MACHINE INCOMING MSG WITH COLLISION */
  } else if (functionId == 6) { // runStateMachineIncomingMsg
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Three inputs required (function to call, wrapper address, receiving node ID).");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t idReceiving;
    idReceiving = mxGetScalar(prhs[2]);
    
    // get the node struct of the node 
    int16_t nodeIdxReceiving = Util_Int8tArrayFindElement(&wrapper->ids[0], idReceiving, wrapper->numNodes);
    Node nodeReceiving = wrapper->nodes[nodeIdxReceiving];

    // create a COLLISION message
    Message msg = Message_Create(COLLISION);

    // run the state machine
    runStateMachineIncomingMsg(nodeReceiving, msg);




  /** SET NODE DRIVER TO RECEIVING */
  } else if (functionId == 7) { // set driver to receiving
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);
    
    int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
    
    // set to receiving
    wrapper->isReceiving[nodeIdx] = true;



  /** SET NODE DRIVER TO NOT RECEIVING */
  } else if (functionId == 8) { // set driver to receiving
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);
    
    int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
    
    // set to not receiving
    wrapper->isReceiving[nodeIdx] = false;


  } else if (functionId == 9) { // increment time (must be called after TIME TIC)
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);
    
    // increment local time of node
    (wrapper->localTimes[id - 1])++;
    
    // check if the local time must be skewed (clock skew)
    if (wrapper->localTimes[id - 1] == (wrapper->lastSkewTime[id - 1] + abs(wrapper->clockSkew[id - 1]))) {
      wrapper->lastSkewTime[id - 1] = wrapper->localTimes[id - 1];

      if (wrapper->clockSkew[id - 1] > 0) {
        // add an additional tic
        ++(wrapper->localTimes[id - 1]);
      } else if (wrapper->clockSkew[id - 1] < 0) {
        // skip one tic
        --(wrapper->localTimes[id - 1]);
      };
    };


  /** GET STATE OF NODE */
  } else if (functionId ==  11) { // getState
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);
    
    // get the node struct of the node 
    int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
    Node node = wrapper->nodes[nodeIdx];
    
    // get the state and add it as an output argument
    plhs[0] = mxCreateDoubleScalar(StateMachine_GetState(node));




    /** GET LOCAL TIME OF A NODE */
    } else if (functionId ==  12) { // getLocalTime
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);
    
    // get the node struct of the node 
    int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
    Node node = wrapper->nodes[nodeIdx];

    // get the local time and add it as an output argument
    plhs[0] = mxCreateDoubleScalar(ProtocolClock_GetLocalTime(node->clock));

  


    /** GET OWN SLOTS OF A NODE */
    } else if (functionId ==  13) { // getOwnSlots
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);
    
    // get the node struct of the node 
    int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
    Node node = wrapper->nodes[nodeIdx];

    // get own slots and add them as an output argument
    plhs[0] = mxCreateNumericMatrix(1,MAX_NUM_OWN_SLOTS,mxINT8_CLASS,mxREAL);

    int8_t ownSlots[MAX_NUM_OWN_SLOTS];
    int8_t numOwn = SlotMap_GetOwnSlots(node, &ownSlots[0], MAX_NUM_OWN_SLOTS);

    int8_t *dataOwnSlots; 
    dataOwnSlots = mxCalloc(MAX_NUM_OWN_SLOTS, sizeof(int8_t));

    for (int elem = 0; elem < numOwn; ++elem) {
      dataOwnSlots[elem] = ownSlots[elem];
    };

    mxSetData(plhs[0], dataOwnSlots);





    /** GET CONFIG OF A NODE */
    } else if (functionId ==  14) { // get config
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);
    
    // get the node struct of the node
    int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
    Node node = wrapper->nodes[nodeIdx];

    // assign field names of config values
    const char *fieldnames[14];
    fieldnames[0] = (char*)mxMalloc(30);
    fieldnames[1] = (char*)mxMalloc(30);
    fieldnames[2] = (char*)mxMalloc(30);
    fieldnames[3] = (char*)mxMalloc(30);
    fieldnames[4] = (char*)mxMalloc(30);
    fieldnames[5] = (char*)mxMalloc(30);
    fieldnames[6] = (char*)mxMalloc(30);
    fieldnames[7] = (char*)mxMalloc(30);
    fieldnames[8] = (char*)mxMalloc(30);
    fieldnames[9] = (char*)mxMalloc(30);
    fieldnames[10] = (char*)mxMalloc(30);
    fieldnames[11] = (char*)mxMalloc(30);
    fieldnames[12] = (char*)mxMalloc(30);
    fieldnames[13] = (char*)mxMalloc(30);

    memcpy(fieldnames[0],"frameLength",sizeof("frameLength"));
    memcpy(fieldnames[1],"slotLength", sizeof("slotLength"));
    memcpy(fieldnames[2],"slotGoal",sizeof("slotGoal"));
    memcpy(fieldnames[3],"initialPingUpperLimit",sizeof("initialPingUpperLimit"));
    memcpy(fieldnames[4],"initialWaitTime",sizeof("initialWaitTime"));
    memcpy(fieldnames[5],"guardPeriodLength",sizeof("guardPeriodLength"));
    memcpy(fieldnames[6],"networkAgeToleranceSameNetwork",sizeof("networkAgeToleranceSameNetwork"));
    memcpy(fieldnames[7],"rangingTimeOut",sizeof("rangingTimeOut"));
    memcpy(fieldnames[8],"rangingWaitTime",sizeof("rangingWaitTime"));
    memcpy(fieldnames[9],"slotExpirationTimeOut",sizeof("slotExpirationTimeOut"));
    memcpy(fieldnames[10],"ownSlotExpirationTimeOut",sizeof("ownSlotExpirationTimeOut"));
    memcpy(fieldnames[11],"absentNeighborTimeOut",sizeof("absentNeighborTimeOut"));
    memcpy(fieldnames[12],"sleepFrames",sizeof("sleepFrames"));
    memcpy(fieldnames[13],"wakeFrames",sizeof("wakeFrames"));

    // allocate memory for the structure and add it as output argument
    plhs[0] = mxCreateStructMatrix(1,1,14,fieldnames);

    // deallocate memory for the fieldnames
    mxFree( fieldnames[0] );
    mxFree( fieldnames[1] );
    mxFree( fieldnames[2] );
    mxFree( fieldnames[3] );
    mxFree( fieldnames[4] );
    mxFree( fieldnames[5] );
    mxFree( fieldnames[6] );
    mxFree( fieldnames[7] );
    mxFree( fieldnames[8] );
    mxFree( fieldnames[9] );
    mxFree( fieldnames[10] );
    mxFree( fieldnames[11] );
    mxFree( fieldnames[12] );
    mxFree( fieldnames[13] );

    // assign the field values
    mxArray *frameLength = mxCreateDoubleScalar(node->config->frameLength);
    mxArray *slotLength = mxCreateDoubleScalar(node->config->slotLength);
    mxArray *slotGoal = mxCreateDoubleScalar(node->config->slotGoal);
    mxArray *initialPingUpperLimit = mxCreateDoubleScalar(node->config->initialPingUpperLimit);
    mxArray *initialWaitTime = mxCreateDoubleScalar(node->config->initialWaitTime);
    mxArray *guardPeriodLength = mxCreateDoubleScalar(node->config->guardPeriodLength);
    mxArray *networkAgeToleranceSameNetwork = mxCreateDoubleScalar(node->config->networkAgeToleranceSameNetwork);
    mxArray *rangingTimeOut = mxCreateDoubleScalar(node->config->rangingTimeOut);
    mxArray *rangingWaitTime = mxCreateDoubleScalar(node->config->rangingWaitTime);
    mxArray *slotExpirationTimeOut = mxCreateDoubleScalar(node->config->slotExpirationTimeOut);
    mxArray *ownSlotExpirationTimeOut = mxCreateDoubleScalar(node->config->ownSlotExpirationTimeOut);
    mxArray *absentNeighborTimeOut = mxCreateDoubleScalar(node->config->absentNeighborTimeOut);
    mxArray *sleepFrames = mxCreateDoubleScalar(node->config->sleepFrames);
    mxArray *wakeFrames = mxCreateDoubleScalar(node->config->wakeFrames);

    mxSetFieldByNumber(plhs[0],0,0, frameLength);
    mxSetFieldByNumber(plhs[0],0,1, slotLength);
    mxSetFieldByNumber(plhs[0],0,2, slotGoal);
    mxSetFieldByNumber(plhs[0],0,3, initialPingUpperLimit);
    mxSetFieldByNumber(plhs[0],0,4, initialWaitTime);
    mxSetFieldByNumber(plhs[0],0,5, guardPeriodLength);
    mxSetFieldByNumber(plhs[0],0,6, networkAgeToleranceSameNetwork);
    mxSetFieldByNumber(plhs[0],0,7, rangingTimeOut);
    mxSetFieldByNumber(plhs[0],0,8, rangingWaitTime);
    mxSetFieldByNumber(plhs[0],0,9, slotExpirationTimeOut);
    mxSetFieldByNumber(plhs[0],0,10, ownSlotExpirationTimeOut);
    mxSetFieldByNumber(plhs[0],0,11, absentNeighborTimeOut);
    mxSetFieldByNumber(plhs[0],0,12, sleepFrames);
    mxSetFieldByNumber(plhs[0],0,13, wakeFrames);
      



    /** GET NETWORK AGE OF A NODE */
    } else if (functionId ==  15) { // get Network Age
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);
    
    // get the node struct of the node
    int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
    Node node = wrapper->nodes[nodeIdx];

    // add network age as output argument
    plhs[0] = mxCreateDoubleScalar(NetworkManager_CalculateNetworkAge(node));



    /** GET NETWORK ID OF A NODE */
    } else if (functionId ==  16) { // get Network Id
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);
    
    // get the node struct of the node
    int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
    Node node = wrapper->nodes[nodeIdx];

    // add network ID as output argument
    plhs[0] = mxCreateDoubleScalar(NetworkManager_GetNetworkId(node));





    /** GET TIME SINCE FRAMESTART OF A NODE */
    } else if (functionId ==  17) { // get Time Since Framestart
    // check number of inputs and outputs
    if(nrhs != 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
    };

    // get the pointer to the wrapper
    Wrapper wrapper;
    wrapper = (long long) mxGetScalar(prhs[1]);

    // get the id from the inputs
    int16_t id;
    id = mxGetScalar(prhs[2]);
    
    // get the node struct of the node 
    int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
    Node node = wrapper->nodes[nodeIdx];

    // add time since frame start as an output argument
    plhs[0] = mxCreateDoubleScalar(TimeKeeping_CalculateTimeSinceFrameStart(node));





    /** GET SLOT MAPS OF A NODE */
    } else if (functionId ==  18) { // get slot maps
      // check number of inputs and outputs
      if(nrhs != 3) {
          mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
      };

      // get the pointer to the wrapper
      Wrapper wrapper;
      wrapper = (long long) mxGetScalar(prhs[1]);

      // get the id from the inputs
      int16_t id;
      id = mxGetScalar(prhs[2]);
    
      // get the node struct of the node
      int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
      Node node = wrapper->nodes[nodeIdx];

      char *fieldnames[6];
      fieldnames[0] = (char*)mxMalloc(20);
      fieldnames[1] = (char*)mxMalloc(20);
      fieldnames[2] = (char*)mxMalloc(20);
      fieldnames[3] = (char*)mxMalloc(20);
      fieldnames[4] = (char*)mxMalloc(20);
      fieldnames[5] = (char*)mxMalloc(20);

      memcpy(fieldnames[0],"oneHopStatus",sizeof("oneHopStatus"));
      memcpy(fieldnames[1],"oneHopIds", sizeof("oneHopIds"));
      memcpy(fieldnames[2],"twoHopStatus",sizeof("twoHopStatus"));
      memcpy(fieldnames[3],"twoHopIds",sizeof("twoHopIds"));
      memcpy(fieldnames[4],"threeHopStatus",sizeof("threeHopStatus"));
      memcpy(fieldnames[5],"threeHopIds",sizeof("threeHopIds"));

      // allocate memory for the structure
      plhs[0] = mxCreateStructMatrix(1,1,6,fieldnames);

      // deallocate memory for the fieldnames
      mxFree( fieldnames[0] );
      mxFree( fieldnames[1] );
      mxFree( fieldnames[2] );
      mxFree( fieldnames[3] );
      mxFree( fieldnames[4] );
      mxFree( fieldnames[5] );

      mxArray *oneHopSlotStatus = mxCreateNumericMatrix(1,NUM_SLOTS,mxINT32_CLASS,mxREAL);
      mxArray *oneHopSlotIds = mxCreateNumericMatrix(1,NUM_SLOTS,mxINT8_CLASS,mxREAL);
      mxArray *twoHopSlotStatus = mxCreateNumericMatrix(1,NUM_SLOTS,mxINT32_CLASS,mxREAL);
      mxArray *twoHopSlotIds = mxCreateNumericMatrix(1,NUM_SLOTS,mxINT8_CLASS,mxREAL);
      mxArray *threeHopSlotStatus = mxCreateNumericMatrix(1,NUM_SLOTS,mxINT32_CLASS,mxREAL);
      mxArray *threeHopSlotIds = mxCreateNumericMatrix(1,NUM_SLOTS,mxINT8_CLASS,mxREAL);

      int32_t *dataOneHopSlotStatus; 
      dataOneHopSlotStatus = mxCalloc(NUM_SLOTS, sizeof(int32_t));
      for (int elem = 0; elem < NUM_SLOTS; ++elem) {
        dataOneHopSlotStatus[elem] = node->slotMap->oneHopSlotsStatus[elem];
      };

      int8_t *dataOneHopSlotIds; 
      dataOneHopSlotIds = mxCalloc(NUM_SLOTS, sizeof(int8_t));
      for (int elem = 0; elem < NUM_SLOTS; ++elem) {
        dataOneHopSlotIds[elem] = node->slotMap->oneHopSlotsIds[elem];
      };

      int32_t *dataTwoHopSlotStatus; 
      dataTwoHopSlotStatus = mxCalloc(NUM_SLOTS, sizeof(int32_t));
      for (int elem = 0; elem < NUM_SLOTS; ++elem) {
        dataTwoHopSlotStatus[elem] = node->slotMap->twoHopSlotsStatus[elem];
      };

      int8_t *dataTwoHopSlotIds; 
      dataTwoHopSlotIds = mxCalloc(NUM_SLOTS, sizeof(int8_t));
      for (int elem = 0; elem < NUM_SLOTS; ++elem) {
        dataTwoHopSlotIds[elem] = node->slotMap->twoHopSlotsIds[elem];
      };

      int32_t *dataThreeHopSlotStatus; 
      dataThreeHopSlotStatus = mxCalloc(NUM_SLOTS, sizeof(int32_t));
      for (int elem = 0; elem < NUM_SLOTS; ++elem) {
        dataThreeHopSlotStatus[elem] = node->slotMap->threeHopSlotsStatus[elem];
      };

      int8_t *dataThreeHopSlotIds; 
      dataThreeHopSlotIds = mxCalloc(NUM_SLOTS, sizeof(int8_t));
      for (int elem = 0; elem < NUM_SLOTS; ++elem) {
        dataThreeHopSlotIds[elem] = node->slotMap->threeHopSlotsIds[elem];
      };

      mxSetData(oneHopSlotStatus, dataOneHopSlotStatus);
      mxSetData(oneHopSlotIds, dataOneHopSlotIds);
      mxSetData(twoHopSlotStatus, dataTwoHopSlotStatus);
      mxSetData(twoHopSlotIds, dataTwoHopSlotIds);
      mxSetData(threeHopSlotStatus, dataThreeHopSlotStatus);
      mxSetData(threeHopSlotIds, dataThreeHopSlotIds);

      mxSetFieldByNumber(plhs[0],0,0, oneHopSlotStatus);
      mxSetFieldByNumber(plhs[0],0,1, oneHopSlotIds);
      mxSetFieldByNumber(plhs[0],0,2, twoHopSlotStatus);
      mxSetFieldByNumber(plhs[0],0,3, twoHopSlotIds);
      mxSetFieldByNumber(plhs[0],0,4, threeHopSlotStatus);
      mxSetFieldByNumber(plhs[0],0,5, threeHopSlotIds);





    /** GET CURRENT SLOT NUM OF A NODE */
    } else if (functionId ==  19) { // get Current Slot Num
      // check number of inputs and outputs
      if(nrhs != 3) {
          mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Four inputs required (function to call, wrapper address, node ID.");
      };

      // get the pointer to the wrapper
      Wrapper wrapper;
      wrapper = (long long) mxGetScalar(prhs[1]);

      // get the id from the inputs
      int16_t id;
      id = mxGetScalar(prhs[2]);

      // get the node struct of the node
      int16_t nodeIdx = Util_Int8tArrayFindElement(&wrapper->ids[0], id, wrapper->numNodes);
      Node node = wrapper->nodes[nodeIdx];

      // add the current slot num as an output argument
      plhs[0] = mxCreateDoubleScalar(TimeKeeping_CalculateCurrentSlotNum(node));
  };
};
