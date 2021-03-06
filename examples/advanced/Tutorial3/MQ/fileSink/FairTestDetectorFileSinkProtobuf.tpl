/*
 * File:   FairTestDetectorFileSink.tpl
 * Author: winckler, A. Rybalchenko
 *
 * Created on March 11, 2014, 12:12 PM
 */

// Implementation of FairTestDetectorFileSink::Run() with Google Protocol Buffers transport data format

#ifdef PROTOBUF
#include "FairTestDetectorPayload.pb.h"

template <>
void FairTestDetectorFileSink<FairTestDetectorHit, TestDetectorProto::HitPayload>::Run()
{
    int receivedMsgs = 0;

    // store the channel references to avoid traversing the map on every loop iteration
    FairMQChannel& dataInChannel = fChannels.at("data-in").at(0);

    while (CheckCurrentState(RUNNING))
    {
        FairMQMessage* msg = fTransportFactory->CreateMessage();

        if (dataInChannel.Receive(msg) > 0)
        {
            receivedMsgs++;
            fOutput->Delete();

            TestDetectorProto::HitPayload hp;
            hp.ParseFromArray(msg->GetData(), msg->GetSize());

            int numEntries = hp.hit_size();

            for (int i = 0; i < numEntries; ++i)
            {
                const TestDetectorProto::Hit& hit = hp.hit(i);
                TVector3 pos(hit.posx(), hit.posy(), hit.posz());
                TVector3 dpos(hit.dposx(), hit.dposy(), hit.dposz());
                new ((*fOutput)[i]) FairTestDetectorHit(hit.detid(), hit.mcindex(), pos, dpos);
            }

            if (fOutput->IsEmpty())
            {
                LOG(ERROR) << "FairTestDetectorFileSink::Run(): No Output array!";
            }

            fTree->Fill();
        }

        delete msg;
    }

    LOG(INFO) << "I've received " << receivedMsgs << " messages!";
}

#endif /* PROTOBUF */
