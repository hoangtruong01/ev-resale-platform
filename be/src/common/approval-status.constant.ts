export const APPROVAL_STATUS = {
  PENDING: 'PENDING',
  APPROVED: 'APPROVED',
  REJECTED: 'REJECTED',
} as const;

export type ApprovalStatusValue =
  (typeof APPROVAL_STATUS)[keyof typeof APPROVAL_STATUS];
