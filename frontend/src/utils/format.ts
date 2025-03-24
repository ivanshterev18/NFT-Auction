export const formatPriceInETH = (priceInWei: string | undefined) => {
  if (!priceInWei) return "0";
  return (parseFloat(priceInWei) / 1e18).toFixed(4); // Convert wei to ETH and format to 4 decimal places
};

export const formatPriceInWei = (priceInETH: string | undefined) => {
  if (!priceInETH) return "0";
  return (parseFloat(priceInETH) * 1e18).toFixed(0); // Convert ETH to wei and format to 0 decimal places
};

export const formatTimeDifference = (endTime: number) => {
  const now = Date.now();
  const difference = endTime * 1000 - now;

  const days = Math.floor(difference / (1000 * 60 * 60 * 24));
  const hours = Math.floor(
    (difference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)
  );
  const minutes = Math.floor((difference % (1000 * 60 * 60)) / (1000 * 60));
  const seconds = Math.floor((difference % (1000 * 60)) / 1000);

  if (days > 0) {
    return `${days}d ${hours}h ${minutes}m`;
  } else if (hours > 0) {
    return `${hours}h ${minutes}m`;
  } else if (minutes >= 5) {
    return `${minutes}m`;
  } else if (minutes < 5 && minutes > 0) {
    return `${minutes}m ${seconds}s`;
  } else if (seconds > 0) {
    return `${seconds}s`;
  }

  return "Ended";
};

export const formatAddress = (address: string) => {
  return address?.slice(0, 6) + "..." + address?.slice(-4);
};
