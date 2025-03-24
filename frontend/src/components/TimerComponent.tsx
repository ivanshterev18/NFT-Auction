import React, { useEffect, useState } from "react";
import { formatTimeDifference } from "../utils/format";

export const TimerComponent = ({ endTime }: { endTime: number }) => {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [time, setTime] = useState<number>(Date.now());

  useEffect(() => {
    const interval = setInterval(() => {
      setTime(Date.now());
    }, 1000); // Update every second

    return () => clearInterval(interval);
  }, []);

  return <span>{formatTimeDifference(endTime)}</span>;
};
