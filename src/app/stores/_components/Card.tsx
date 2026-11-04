"use client";

import { useState } from "react";

export default function Card({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div
      onClick={() => setIsOpen(!isOpen)}
      className="cursor-pointer border p-4 rounded-md"
    >
      <h2>{title}</h2>
      <p className={!isOpen ? "hidden" : ""}>{description}</p>
    </div>
  );
}
